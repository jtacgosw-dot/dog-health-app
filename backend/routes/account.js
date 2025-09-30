const express = require('express');
const supabase = require('../utils/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.delete('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const { error: entitlementError } = await supabase
            .from('entitlements')
            .delete()
            .eq('user_id', userId);

        if (entitlementError) {
            console.error('Error deleting entitlements:', entitlementError);
        }

        const { error: userError } = await supabase
            .from('users')
            .delete()
            .eq('id', userId);

        if (userError) {
            console.error('Error deleting user:', userError);
            return res.status(500).json({ error: 'Failed to delete account' });
        }

        res.json({
            success: true,
            message: 'Account and all associated data have been deleted'
        });

    } catch (error) {
        console.error('Account deletion error:', error);
        res.status(500).json({ error: 'Failed to delete account' });
    }
});

module.exports = router;
