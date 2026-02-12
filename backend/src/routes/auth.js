const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const { verifyAppleToken } = require('../services/apple-auth');
const { body, validationResult } = require('express-validator');
const supabase = require('../services/supabase');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

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

/**
 * POST /api/auth/register
 * Register with email and password
 */
router.post('/register',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('fullName').notEmpty().withMessage('Full name is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password, fullName } = req.body;

      const { data: existingUser } = await supabase
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase())
        .single();

      if (existingUser) {
        return res.status(409).json({
          success: false,
          error: 'An account with this email already exists'
        });
      }

      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(password, salt);

      const userId = require('crypto').randomUUID();

      const { data: newUser, error: createError } = await supabase
        .from('users')
        .insert([{
          id: userId,
          email: email.toLowerCase(),
          full_name: fullName,
          password_hash: passwordHash,
          auth_provider: 'email',
          subscription_status: 'free'
        }])
        .select()
        .single();

      if (createError) {
        console.error('Failed to create user:', createError);
        return res.status(500).json({ error: 'Failed to create account', details: createError.message });
      }

      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        return res.status(500).json({ error: 'Server configuration error' });
      }
      const token = jwt.sign(
        { userId: newUser.id, email: newUser.email },
        jwtSecret,
        { expiresIn: '30d' }
      );

      res.status(201).json({
        success: true,
        user: {
          id: newUser.id,
          email: newUser.email,
          fullName: newUser.full_name,
          subscriptionStatus: newUser.subscription_status
        },
        token: token
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({
        success: false,
        error: 'Registration failed',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/auth/login
 * Sign in with email and password
 */
router.post('/login',
  [
    body('email').isEmail().withMessage('Valid email is required'),
    body('password').notEmpty().withMessage('Password is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { email, password } = req.body;

      const { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email.toLowerCase())
        .single();

      if (error || !user) {
        return res.status(401).json({
          success: false,
          error: 'Invalid email or password'
        });
      }

      if (!user.password_hash) {
        return res.status(401).json({
          success: false,
          error: 'This account uses a different sign-in method (Apple or Google)'
        });
      }

      const isValidPassword = await bcrypt.compare(password, user.password_hash);
      if (!isValidPassword) {
        return res.status(401).json({
          success: false,
          error: 'Invalid email or password'
        });
      }

      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        return res.status(500).json({ error: 'Server configuration error' });
      }
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        jwtSecret,
        { expiresIn: '30d' }
      );

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
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        error: 'Login failed',
        message: error.message
      });
    }
  }
);

/**
 * POST /api/auth/google
 * Sign in with Google ID token
 */
router.post('/google',
  [
    body('idToken').notEmpty().withMessage('Google ID token is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { idToken } = req.body;

      const ticket = await googleClient.verifyIdToken({
        idToken: idToken,
        audience: process.env.GOOGLE_CLIENT_ID
      });
      const payload = ticket.getPayload();

      if (!payload || !payload.email) {
        return res.status(401).json({
          success: false,
          error: 'Invalid Google token'
        });
      }

      const googleUserId = payload.sub;
      const googleEmail = payload.email;
      const googleName = payload.name || '';

      let { data: user } = await supabase
        .from('users')
        .select('*')
        .eq('email', googleEmail.toLowerCase())
        .single();

      if (!user) {
        const userId = require('crypto').randomUUID();
        const { data: newUser, error: createError } = await supabase
          .from('users')
          .insert([{
            id: userId,
            email: googleEmail.toLowerCase(),
            full_name: googleName,
            google_user_id: googleUserId,
            auth_provider: 'google',
            subscription_status: 'free'
          }])
          .select()
          .single();

        if (createError) {
          console.error('Failed to create Google user:', createError);
          return res.status(500).json({ error: 'Failed to create account', details: createError.message });
        }
        user = newUser;
      } else if (!user.google_user_id) {
        await supabase
          .from('users')
          .update({ google_user_id: googleUserId, auth_provider: user.auth_provider ? user.auth_provider + ',google' : 'google' })
          .eq('id', user.id);
      }

      const jwtSecret = process.env.JWT_SECRET;
      if (!jwtSecret) {
        return res.status(500).json({ error: 'Server configuration error' });
      }
      const token = jwt.sign(
        { userId: user.id, email: user.email },
        jwtSecret,
        { expiresIn: '30d' }
      );

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
      console.error('Google Sign In error:', error);
      res.status(500).json({
        success: false,
        error: 'Google authentication failed',
        message: error.message
      });
    }
  }
);

module.exports = router;
