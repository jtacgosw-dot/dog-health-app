const express = require('express');
const fetch = require('node-fetch');
const supabase = require('../utils/supabase');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

const APP_STORE_SERVER_API_BASE = {
    sandbox: 'https://api.storekit-itunes.apple.com/inApps/v1',
    production: 'https://api.storekit.apple.com/inApps/v1'
};

async function verifyWithAppStore(transactionId, environment = 'sandbox') {
    const baseUrl = APP_STORE_SERVER_API_BASE[environment];
    const url = `${baseUrl}/transactions/${transactionId}`;

    const response = await fetch(url, {
        method: 'GET',
        headers: {
            'Authorization': `Bearer ${generateJWT()}`,
            'Content-Type': 'application/json'
        }
    });

    if (!response.ok) {
        throw new Error(`App Store API error: ${response.status}`);
    }

    return await response.json();
}

function generateJWT() {
    const jwt = require('jsonwebtoken');
    const now = Math.floor(Date.now() / 1000);
    
    const payload = {
        iss: process.env.APPLE_ISSUER_ID,
        iat: now,
        exp: now + 3600,
        aud: 'appstoreconnect-v1',
        bid: process.env.BUNDLE_ID
    };

    return jwt.sign(payload, process.env.APPLE_PRIVATE_KEY.replace(/\\n/g, '\n'), {
        algorithm: 'ES256',
        keyid: process.env.APPLE_KEY_ID
    });
}

router.post('/verify', authenticateToken, async (req, res) => {
    try {
        const { transactionId } = req.body;
        const userId = req.user.userId;

        if (!transactionId) {
            return res.status(400).json({ error: 'Transaction ID is required' });
        }

        let transactionInfo;
        let environment = process.env.APPLE_ENV || 'sandbox';

        try {
            transactionInfo = await verifyWithAppStore(transactionId, environment);
        } catch (error) {
            if (environment === 'production') {
                try {
                    transactionInfo = await verifyWithAppStore(transactionId, 'sandbox');
                    environment = 'sandbox';
                } catch (sandboxError) {
                    console.error('Failed to verify with both environments:', error, sandboxError);
                    return res.status(400).json({ error: 'Invalid transaction' });
                }
            } else {
                console.error('Transaction verification failed:', error);
                return res.status(400).json({ error: 'Invalid transaction' });
            }
        }

        const transaction = transactionInfo.signedTransactionInfo;
        const decodedTransaction = JSON.parse(Buffer.from(transaction.split('.')[1], 'base64').toString());

        const productId = decodedTransaction.productId;
        const expiresDate = decodedTransaction.expiresDate ? new Date(decodedTransaction.expiresDate) : null;
        const isActive = expiresDate ? expiresDate > new Date() : true;

        const { error: updateError } = await supabase
            .from('entitlements')
            .upsert({
                user_id: userId,
                is_active: isActive,
                product_id: productId,
                renews_at: expiresDate,
                updated_at: new Date().toISOString()
            });

        if (updateError) {
            console.error('Error updating entitlements:', updateError);
            return res.status(500).json({ error: 'Failed to update entitlements' });
        }

        res.json({
            success: true,
            entitlement: {
                isActive,
                productId,
                renewsAt: expiresDate,
                environment
            }
        });

    } catch (error) {
        console.error('IAP verification error:', error);
        res.status(500).json({ error: 'Verification failed' });
    }
});

module.exports = router;
