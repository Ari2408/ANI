import express from 'express';
import cors from 'cors';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initDatabaseSeed } from './db.js';
import { authRouter } from './routes/auth.js';
import { eldersRouter } from './routes/elders.js';
import { cardsRouter } from './routes/cards.js';
import { playRouter } from './routes/play.js';
import { statsRouter } from './routes/stats.js';
import { exportRouter } from './routes/export.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const UPLOADS_DIR = path.resolve(__dirname, '../../uploads');

const app = express();
const PORT = process.env.PORT || 5050;

// Middleware
app.use(cors());
app.use(express.json({ limit: '25mb' }));
app.use(express.urlencoded({ extended: true, limit: '25mb' }));

// Static uploads serving
app.use('/uploads', express.static(UPLOADS_DIR));

// Seed database with starter profiles, cards, and past stats
initDatabaseSeed();

// Routes
app.use('/api/auth', authRouter);
app.use('/api/elders', eldersRouter);
app.use('/api/cards', cardsRouter);
app.use('/api/play', playRouter);
app.use('/api/stats', statsRouter);
app.use('/api/export', exportRouter);

app.get('/api/health', (_req, res) => {
  res.json({ status: 'healthy', app: 'Memory Snap Backend', time: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`[Memory Snap Server] Running on http://localhost:${PORT}`);
});
