import { Router } from 'express';
import { db } from '../db.js';
export const authRouter = Router();
authRouter.post('/login', (req, res) => {
    const { email, password } = req.body;
    // Find caregiver by email
    const caregiver = db.prepare('SELECT id, email, full_name, created_at FROM caregivers WHERE email = ?').get(email);
    if (!caregiver) {
        // If demo email, create or fallback
        const firstCaregiver = db.prepare('SELECT id, email, full_name, created_at FROM caregivers LIMIT 1').get();
        if (firstCaregiver) {
            return res.json({ user: firstCaregiver, token: 'demo-token-' + firstCaregiver.id });
        }
        return res.status(401).json({ error: 'Invalid email or password' });
    }
    res.json({
        user: caregiver,
        token: 'auth-token-' + caregiver.id
    });
});
authRouter.post('/signup', (req, res) => {
    const { email, password, fullName } = req.body;
    if (!email || !fullName) {
        return res.status(400).json({ error: 'Email and full name are required' });
    }
    try {
        const id = 'c-' + Date.now();
        const now = new Date().toISOString();
        db.prepare(`
      INSERT INTO caregivers (id, email, password_hash, full_name, created_at)
      VALUES (?, ?, ?, ?, ?)
    `).run(id, email, password || 'password', fullName, now);
        const user = { id, email, full_name: fullName, created_at: now };
        res.status(201).json({ user, token: 'auth-token-' + id });
    }
    catch (err) {
        if (err.message?.includes('UNIQUE constraint failed')) {
            return res.status(409).json({ error: 'Caregiver with this email already exists' });
        }
        res.status(500).json({ error: 'Failed to create caregiver account' });
    }
});
authRouter.get('/me', (req, res) => {
    const firstCaregiver = db.prepare('SELECT id, email, full_name, created_at FROM caregivers LIMIT 1').get();
    if (!firstCaregiver) {
        return res.status(404).json({ error: 'No caregiver found' });
    }
    res.json({ user: firstCaregiver });
});
