const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const { verifyAppleToken } = require('../services/apple-auth');
const { body, validationResult } = require('express-validator');
const supabase = require('../services/supabase');

/**
 * POST /api/auth/apple
 * Sign in with Apple
 */
router.post('/apple',
  [
    body('identityToken').notEmpty().withMessage('Identity token is required'),
    body('authorizationCode').notEmpty().withMessage('Authorization code is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { identityToken, authorizationCode, user } = req.body;

      const result = await verifyAppleToken(identityToken, authorizationCode, user);

      res.status(200).json({
        success: true,
        user: {
          id: result.user.id,
          email: result.user.email,
          fullName: result.user.full_name,
          subscriptionStatus: result.user.subscription_status
        },
        token: result.token
      });
    } catch (error) {
      console.error('Apple Sign In error:', error);
      res.status(500).json({
        success: false,
        error: 'Authentication failed',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/auth/dev
 * Development-only authentication endpoint
 * Creates or retrieves a test user and returns a JWT token
 * ONLY available when NODE_ENV=development
 */
router.post('/dev',
  async (req, res) => {
    try {
      // Only allow in development mode
      if (process.env.NODE_ENV !== 'development') {
        return res.status(404).json({ error: 'Not found' });
      }

      const devEmail = 'dev@test.com';
      const devUserId = '00000000-0000-0000-0000-000000000001';
      const devAppleUserId = 'dev.apple.user.id.for.testing';
      const devAppleSub = 'dev-apple-subscription-id';

      // Check if dev user exists
      let { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', devEmail)
        .single();

      // Create dev user if doesn't exist
      if (error || !user) {
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            id: devUserId,
            apple_user_id: devAppleUserId,
            apple_sub: devAppleSub,
            email: devEmail,
            full_name: 'Dev User',
            subscription_status: 'premium',
            subscription_expires_at: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000).toISOString()
          }])
          .select()
          .single();

        if (createError) {
          console.error('Failed to create dev user:', createError);
          return res.status(500).json({ error: 'Failed to create dev user', details: createError.message });
        }
        user = newUser;
      }

      // Generate JWT token
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        console.error('JWT_SECRET environment variable is not set');
        return res.status(500).json({ error: 'Server configuration error' });
      }
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        jwtSecret,
        { expiresIn: '30d' }
      );

      console.log('Dev auth: Generated token for user:', user.email);

      res.status(200).json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.full_name,
          subscriptionStatus: user.subscription_status
        },
        token: token
      });
    } catch (error) {
      console.error('Dev auth error:', error);
      res.status(500).json({
        success: false,
        error: 'Dev authentication failed',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/auth/guest
 * Guest authentication endpoint
 * Creates or retrieves a guest user based on device ID and returns a JWT token
 * This allows testing the app without Apple Sign In
 */
router.post('/guest',
  async (req, res) => {
    try {
      const { deviceId } = req.body;
      
      // Generate a unique guest ID based on device ID or random
      const guestId = deviceId 
        ? `guest-${deviceId.substring(0, 32)}`
        : `guest-${Date.now()}-${Math.random().toString(36).substring(7)}`;
      
      const guestEmail = `${guestId}@guest.petly.app`;
      const guestUserId = require('crypto').createHash('md5').update(guestId).digest('hex');
      const formattedUserId = `${guestUserId.substring(0, 8)}-${guestUserId.substring(8, 12)}-${guestUserId.substring(12, 16)}-${guestUserId.substring(16, 20)}-${guestUserId.substring(20, 32)}`;

      // Check if guest user exists
      let { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', guestEmail)
        .single();

      // Create guest user if doesn't exist
      if (error || !user) {
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            id: formattedUserId,
            apple_user_id: guestId,
            apple_sub: guestId,
            email: guestEmail,
            full_name: 'Guest User',
            subscription_status: 'free',
            subscription_expires_at: null
          }])
          .select()
          .single();

        if (createError) {
          console.error('Failed to create guest user:', createError);
          return res.status(500).json({ error: 'Failed to create guest user', details: createError.message });
        }
        user = newUser;
      }

      // Generate JWT token (valid for 7 days for guests)
      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        console.error('JWT_SECRET environment variable is not set');
        return res.status(500).json({ error: 'Server configuration error' });
      }
      const token = jwt.sign(
        { userId: user.id, email: user.email, isGuest: true },
        jwtSecret,
        { expiresIn: '7d' }
      );

      console.log('Guest auth: Generated token for user:', user.email);

      res.status(200).json({
        success: true,
        user: {
          id: user.id,
          email: user.email,
          fullName: user.full_name,
          subscriptionStatus: user.subscription_status
        },
        token: token
      });
    } catch (error) {
      console.error('Guest auth error:', error);
      res.status(500).json({
        success: false,
        error: 'Guest authentication failed',
        message: error.message
      });
    }
  }
);

module.exports = router;
