const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const connectDB = require('./DB/connect');
const { errorHandling } = require('./middleware/centralizedMiddleware');

if (process.env.NODE_ENV !== 'production') dotenv.config();

const requiredValues = ['PORT', 'MONGODB_URI', 'JWT_SECRET', 'BOOTSTRAP_SECRET', 'CORS_ORIGIN'];

const validateEnvironment = () => {
  const missingValues = requiredValues.filter((value) => !process.env[value]);
  if (missingValues.length) throw new Error(`Missing required environment values: ${missingValues.join(', ')}`);
  if (process.env.JWT_SECRET.length < 32) throw new Error('JWT_SECRET must contain at least 32 characters');
  if (process.env.JWT_SECRET === process.env.BOOTSTRAP_SECRET) throw new Error('JWT_SECRET and BOOTSTRAP_SECRET must be different');
};

const createApp = ({ beforeRoutes } = {}) => {
  const app = express();

  app.disable('x-powered-by');
  app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Referrer-Policy', 'no-referrer');
    next();
  });
  app.use(express.json({ limit: '1mb' }));
  app.use(cors({ origin: process.env.CORS_ORIGIN === '*' ? true : process.env.CORS_ORIGIN.split(',').map((value) => value.trim()) }));

  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  if (beforeRoutes) app.use('/api', beforeRoutes);
  app.use('/api/auth', require('./routes/authRoutes'));
  app.use('/api/tasks', require('./routes/taskRoutes'));
  app.use('/api/tickets', require('./routes/ticketRoutes'));
  app.use('/api/announcements', require('./routes/announcementRoutes'));
  app.use('/api/users', require('./routes/userRoutes'));
  app.use((req, res) => res.status(404).json({ message: 'resource not found' }));
  app.use(errorHandling);

  return app;
};

const app = createApp();

const startServer = async () => {
  try {
    validateEnvironment();
    await connectDB();
    app.listen(process.env.PORT, () => console.log(`NAPS API listening on port ${process.env.PORT}`));
  } catch (err) {
    console.error('The API could not start', err);
    process.exitCode = 1;
  }
};

if (require.main === module) startServer();

module.exports = { app, createApp, startServer };
