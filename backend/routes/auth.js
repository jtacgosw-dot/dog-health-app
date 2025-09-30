const express = require('express');
const appleSignin = require('apple-signin-auth');
const supabase = require('../utils/supabase');
const { signToken } = require('../utils/jwt');

const router = express.Router();

router.post('/apple', async (req, res) => {
    try {
        const { identityToken } = req.body;

        if (!identityToken) {
            return res.status(400).json({ error: 'Identity token is required' });
        }

        const appleIdTokenClaims = await appleSignin.verifyIdToken(identityToken, {
            audience: process.env.BUNDLE_ID,
            ignoreExpiration: false,
        });

        const appleSub = appleIdTokenClaims.sub;

        const { data: existingUser, error: fetchError } = await supabase
            .from('users')
            .select('*')
            .eq('apple_sub', appleSub)
            .single();

        let user;
        if (fetchError && fetchError.code === 'PGRST116') {
            const { data: newUser, error: insertError } = await supabase
                .from('users')
                .insert([{ apple_sub: appleSub }])
                .select()
                .single();

            if (insertError) {
                console.error('Error creating user:', insertError);
                return res.status(500).json({ error: 'Failed to create user' });
            }

            const { error: entitlementError } = await supabase
                .from('entitlements')
                .insert([{ user_id: newUser.id, is_active: false }]);

            if (entitlementError) {
                console.error('Error creating entitlement:', entitlementError);
            }

            user = newUser;
        } else if (fetchError) {
            console.error('Error fetching user:', fetchError);
            return res.status(500).json({ error: 'Database error' });
        } else {
            user = existingUser;
        }

        const token = signToken({ userId: user.id, appleSub: user.apple_sub });

        res.json({
            success: true,
            token,
            user: {
                id: user.id,
                appleSub: user.apple_sub,
                createdAt: user.created_at
            }
        });

    } catch (error) {
        console.error('Apple authentication error:', error);
        res.status(400).json({ error: 'Invalid Apple identity token' });
    }
});

module.exports = router;
