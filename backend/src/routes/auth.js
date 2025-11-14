const express = require('express');
const router = express.Router();
const { verifyAppleToken } = require('../services/apple-auth');
const { body, validationResult } = require('express-validator');

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

module.exports = router;
