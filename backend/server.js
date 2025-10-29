require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

let supabase = null;
if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
  supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY
  );
  console.log('Supabase client initialized');
} else {
  console.warn('Supabase credentials not found - client not initialized');
}

app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'dog-health-app-backend'
  });
});

app.post('/api/auth/apple', (req, res) => {
  res.status(501).json({
    message: 'Apple Sign In endpoint - to be implemented',
    endpoint: '/api/auth/apple'
  });
});

app.post('/api/iap/verify', (req, res) => {
  res.status(501).json({
    message: 'IAP verification endpoint - to be implemented',
    endpoint: '/api/iap/verify'
  });
});

app.get('/api/entitlements', (req, res) => {
  res.status(501).json({
    message: 'Entitlements check endpoint - to be implemented',
    endpoint: '/api/entitlements'
  });
});

app.post('/api/chat', (req, res) => {
  res.status(501).json({
    message: 'Chat endpoint - to be implemented',
    endpoint: '/api/chat'
  });
});

app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

app.listen(PORT, () => {
  console.log(`Dog Health App backend listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
