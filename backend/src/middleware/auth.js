const jwt = require('jsonwebtoken');
const supabase = require('../services/supabase');

/**
 * Middleware to verify JWT token and attach user to request
 * In development mode (NODE_ENV=development), authentication can be bypassed
 */
const authenticateToken = async (req, res, next) => {
  try {
    // Development mode bypass - allows testing without authentication
    if (process.env.NODE_ENV === 'development' && process.env.DEV_BYPASS_AUTH === 'true') {
      // Create a mock user for development testing
      req.user = {
        id: 'dev-test-user-id',
        email: 'dev@test.com',
        name: 'Dev Test User',
        subscription_status: 'premium',
        subscription_expires_at: null
      };
      req.auth = { userId: 'dev-test-user-id', isGuest: true };
      console.log('[DEV MODE] Authentication bypassed for development testing');
      return next();
    }

    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ error: 'Authentication token required' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', decoded.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid token or user not found' });
    }

    req.user = user;
    req.auth = decoded; // Preserve JWT claims (includes isGuest flag)
    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    return res.status(500).json({ error: 'Authentication failed' });
  }
};

/**
 * Middleware to check if user has active subscription
 */
const requireSubscription = async (req, res, next) => {
  try {
    const user = req.user;

    if (user.subscription_status === 'free') {
      return res.status(403).json({ 
        error: 'Subscription required',
        message: 'This feature requires an active subscription'
      });
    }

    if (user.subscription_expires_at && new Date(user.subscription_expires_at) < new Date()) {
      return res.status(403).json({ 
        error: 'Subscription expired',
        message: 'Your subscription has expired. Please renew to continue.'
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({ error: 'Subscription check failed' });
  }
};

/**
 * Middleware to allow guest users OR users with active subscription
 * Guest users (identified by isGuest claim in JWT) can access features for testing
 */
const requireSubscriptionOrGuest = async (req, res, next) => {
  try {
    // Allow guest users to bypass subscription check (for testing)
    if (req.auth && req.auth.isGuest === true) {
      return next();
    }

    // For non-guest users, check subscription
    const user = req.user;

    if (user.subscription_status === 'free') {
      return res.status(403).json({ 
        error: 'Subscription required',
        message: 'This feature requires an active subscription'
      });
    }

    if (user.subscription_expires_at && new Date(user.subscription_expires_at) < new Date()) {
      return res.status(403).json({ 
        error: 'Subscription expired',
        message: 'Your subscription has expired. Please renew to continue.'
      });
    }

    next();
  } catch (error) {
    return res.status(500).json({ error: 'Subscription check failed' });
  }
};

module.exports = {
  authenticateToken,
  requireSubscription,
  requireSubscriptionOrGuest
};
