const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const pool = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: 'Требуется авторизация' });

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Недействительный токен' });
        req.user = user;
        next();
    });
}

app.post('/api/auth/register', async (req, res) => {
    const { name, nickname, email, password } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ error: 'Заполните все обязательные поля' });
    }

    try {
        const userCheck = await pool.query('SELECT id FROM users WHERE email = $1 OR nickname = $2', [email, nickname]);
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ error: 'Пользователь с таким email или никнеймом уже существует' });
        }

        const salt = await bcrypt.genSalt(10);
        const passwordHash = await bcrypt.hash(password, salt);

        const newUser = await pool.query(
            'INSERT INTO users (name, nickname, email, password_hash) VALUES ($1, $2, $3, $4) RETURNING id, name, nickname, email',
            [name, nickname || '@user', email, passwordHash]
        );

        const user = newUser.rows[0];
        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '30d' });

        res.status(201).json({ token, user });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (result.rows.length === 0) {
            return res.status(400).json({ error: 'Неверный email или пароль' });
        }

        const user = result.rows[0];
        const isMatch = await bcrypt.compare(password, user.password_hash);
        if (!isMatch) {
            return res.status(400).json({ error: 'Неверный email или пароль' });
        }

        const token = jwt.sign({ id: user.id, email: user.email }, process.env.JWT_SECRET, { expiresIn: '30d' });

        res.json({
            token,
            user: {
                id: user.id,
                name: user.name,
                nickname: user.nickname,
                email: user.email,
            },
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});

app.get('/api/user/profile', authenticateToken, async (req, res) => {
    try {
        const userRes = await pool.query('SELECT id, name, nickname, email FROM users WHERE id = $1', [req.user.id]);
        const petsRes = await pool.query('SELECT id, name, image_path FROM pets WHERE user_id = $1 ORDER BY id DESC', [req.user.id]);

        if (userRes.rows.length === 0) {
            return res.status(404).json({ error: 'Пользователь не найден' });
        }

        res.json({
            user: userRes.rows[0],
            pets: petsRes.rows,
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});

app.post('/api/pets', authenticateToken, async (req, res) => {
    const { name, imagePath } = req.body;
    try {
        const newPet = await pool.query(
            'INSERT INTO pets (user_id, name, image_path) VALUES ($1, $2, $3) RETURNING id, name, image_path',
            [req.user.id, name, imagePath]
        );
        res.status(201).json(newPet.rows[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});

app.delete('/api/pets/:id', authenticateToken, async (req, res) => {
    const petId = req.params.id;
    try {
        await pool.query('DELETE FROM pets WHERE id = $1 AND user_id = $2', [petId, req.user.id]);
        res.json({ message: 'Питомец удален' });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Ошибка сервера' });
    }
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Сервер запущен на http://localhost:${PORT}`);
    });
}

module.exports = app;