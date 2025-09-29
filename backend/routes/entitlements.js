const express = require('express');
const supabase = require('../utils/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.get('/', authenticateToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const { data: entitlement, error } = await supabase
            .from('entitlements')
            .select('*')
            .eq('user_id', userId)
            .single();

        if (error && error.code !== 'PGRST116') {
            console.error('Error fetching entitlements:', error);
            return res.status(500).json({ error: 'Failed to fetch entitlements' });
        }

        if (!entitlement) {
            return res.json({
                isActive: false,
                productId: null,
                renewsAt: null
            });
        }

        const isActive = entitlement.is_active && 
            (!entitlement.renews_at || new Date(entitlement.renews_at) > new Date());

        if (entitlement.is_active !== isActive) {
            await supabase
                .from('entitlements')
                .update({ is_active: isActive, updated_at: new Date().toISOString() })
                .eq('user_id', userId);
        }

        res.json({
            isActive,
            productId: entitlement.product_id,
            renewsAt: entitlement.renews_at,
            updatedAt: entitlement.updated_at
        });

    } catch (error) {
        console.error('Entitlements error:', error);
        res.status(500).json({ error: 'Failed to fetch entitlements' });
    }
});

module.exports = router;
