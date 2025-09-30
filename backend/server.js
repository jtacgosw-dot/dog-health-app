const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const chatRoutes = require('./routes/chat');
const authRoutes = require('./routes/auth');
const iapRoutes = require('./routes/iap');
const entitlementsRoutes = require('./routes/entitlements');
const accountRoutes = require('./routes/account');
const webhookRoutes = require('./routes/webhook');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

app.use('/api/chat', chatRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/iap', iapRoutes);
app.use('/api/entitlements', entitlementsRoutes);
app.use('/api/account', accountRoutes);
app.use('/api/webhook', webhookRoutes);

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    service: 'dog-health-backend'
  });
});

app.get('/', (req, res) => {
  res.json({ 
    message: 'Dog Health API Server',
    version: '1.0.0',
    endpoints: [
      'GET /api/health',
      'POST /api/chat',
      'POST /api/auth/apple',
      'POST /api/iap/verify',
      'GET /api/entitlements',
      'DELETE /api/account',
      'POST /api/webhook/apple-asn'
    ]
  });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    error: 'Something went wrong!',
    message: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

app.listen(PORT, () => {
  console.log(`Dog Health API server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
});
