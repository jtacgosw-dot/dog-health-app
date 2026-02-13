const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { verifyReceipt, checkSubscriptionStatus } = require('../services/subscription');
const { body, validationResult } = require('express-validator');

/**
 * POST /api/iap/verify
 * Verify App Store receipt
 */
router.post('/verify',
  authenticateToken,
  [
    body('receiptData').notEmpty().withMessage('Receipt data is required')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { receiptData } = req.body;
      const userId = req.user.id;

      const result = await verifyReceipt(receiptData, userId);

      res.status(200).json({
        success: true,
        subscription: result.subscription
      });
    } catch (error) {
      console.error('Receipt verification error:', error);
      res.status(500).json({
        success: false,
        error: 'Receipt verification failed',
        message: error.message
      });
    }
  }
);

/**
 * GET / (mounted at /api/entitlements)
 * Check user's subscription entitlements
 */
router.get('/',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;

      const status = await checkSubscriptionStatus(userId);

      res.status(200).json({
        hasActiveSubscription: status.isSubscribed,
        subscriptionStatus: status.subscriptionType || 'free',
        expiresAt: status.expiresAt || null
      });
    } catch (error) {
      console.error('Entitlements check error:', error);
      res.status(500).json({
        hasActiveSubscription: false,
        subscriptionStatus: 'free',
        error: 'Failed to check entitlements'
      });
    }
  }
);

/**
 * GET /entitlements (mounted at /api/iap/entitlements)
 * Check user's subscription entitlements (legacy path)
 */
router.get('/entitlements',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;

      const status = await checkSubscriptionStatus(userId);

      res.status(200).json({
        hasActiveSubscription: status.isSubscribed,
        subscriptionStatus: status.subscriptionType || 'free',
        expiresAt: status.expiresAt || null
      });
    } catch (error) {
      console.error('Entitlements check error:', error);
      res.status(500).json({
        hasActiveSubscription: false,
        subscriptionStatus: 'free',
        error: 'Failed to check entitlements'
      });
    }
  }
);

module.exports = router;
