const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const supabase = require('../services/supabase');
const { body, validationResult } = require('express-validator');

/**
 * GET /api/users/me
 * Get current user profile
 */
router.get('/me',
  authenticateToken,
  async (req, res) => {
    try {
      const userId = req.user.id;

      const { data: user, error } = await supabase
        .from('users')
        .select('id, email, full_name, subscription_status, subscription_expires_at, created_at')
        .eq('id', userId)
        .single();

      if (error) {
        throw new Error('Failed to fetch user profile');
      }

      res.status(200).json({
        success: true,
        user
      });
    } catch (error) {
      console.error('Fetch user profile error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to fetch user profile',
        message: error.message
      });
    }
  }
);

/**
 * PUT /api/users/me
 * Update current user profile
 */
router.put('/me',
  authenticateToken,
  [
    body('fullName').optional().isString().withMessage('Full name must be a string'),
    body('email').optional().isEmail().withMessage('Invalid email address')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const userId = req.user.id;
      const { fullName, email } = req.body;

      const updates = {};
      if (fullName !== undefined) updates.full_name = fullName;
      if (email !== undefined) updates.email = email;

      if (Object.keys(updates).length === 0) {
        return res.status(400).json({ error: 'No fields to update' });
      }

      const { data: user, error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', userId)
        .select('id, email, full_name, subscription_status, subscription_expires_at')
        .single();

      if (error) {
        throw new Error('Failed to update user profile');
      }

      res.status(200).json({
        success: true,
        user
      });
    } catch (error) {
      console.error('Update user profile error:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to update user profile',
        message: error.message
      });
    }
  }
);

module.exports = router;
