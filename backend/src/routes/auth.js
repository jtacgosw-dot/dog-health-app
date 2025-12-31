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
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        process.env.JWT_SECRET || 'dev-secret-key',
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

module.exports = router;
