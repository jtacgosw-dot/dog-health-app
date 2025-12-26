require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const authRoutes = require('./src/routes/auth');
const chatRoutes = require('./src/routes/chat');
const userRoutes = require('./src/routes/users');
const dogRoutes = require('./src/routes/dogs');
const subscriptionRoutes = require('./src/routes/subscription');
const healthLogsRoutes = require('./src/routes/healthLogs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());

app.use(cors({
  origin: process.env.NODE_ENV === 'production' 
    ? ['https://dog-health-app.onrender.com'] 
    : '*',
  credentials: true
}));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'dog-health-app-backend',
    version: '2.0.0'
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/users', userRoutes);
app.use('/api/dogs', dogRoutes);
app.use('/api/health-logs', healthLogsRoutes);
app.use('/api/iap', subscriptionRoutes);
app.use('/api/entitlements', subscriptionRoutes);

app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path,
    message: 'The requested endpoint does not exist'
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  
  const errorResponse = {
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'An unexpected error occurred'
  };
  
  if (process.env.NODE_ENV === 'development') {
    errorResponse.stack = err.stack;
  }
  
  res.status(err.status || 500).json(errorResponse);
});

app.listen(PORT, () => {
  console.log(`🚀 Dog Health App backend listening on port ${PORT}`);
  console.log(`📦 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🏥 Health check: http://localhost:${PORT}/api/health`);
  console.log(`\n📋 Available endpoints:`);
  console.log(`   POST   /api/auth/apple`);
  console.log(`   POST   /api/chat`);
  console.log(`   GET    /api/chat/conversations`);
  console.log(`   GET    /api/chat/conversations/:id/messages`);
  console.log(`   POST   /api/chat/messages/:id/feedback`);
  console.log(`   GET    /api/users/me`);
  console.log(`   PUT    /api/users/me`);
  console.log(`   GET    /api/dogs`);
  console.log(`   GET    /api/dogs/:id`);
  console.log(`   POST   /api/dogs`);
  console.log(`   PUT    /api/dogs/:id`);
  console.log(`   DELETE /api/dogs/:id`);
  console.log(`   GET    /api/health-logs`);
  console.log(`   POST   /api/health-logs`);
  console.log(`   POST   /api/health-logs/batch`);
  console.log(`   POST   /api/health-logs/sync`);
  console.log(`   PUT    /api/health-logs/:id`);
  console.log(`   DELETE /api/health-logs/:id`);
  console.log(`   POST   /api/iap/verify`);
  console.log(`   GET    /api/entitlements`);
});

module.exports = app;
