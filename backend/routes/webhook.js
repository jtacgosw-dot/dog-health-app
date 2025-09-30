const express = require('express');
const supabase = require('../utils/supabase');

const router = express.Router();

const processedTransactions = new Set();

router.post('/apple-asn', express.raw({ type: 'application/json' }), async (req, res) => {
    try {
        const notification = JSON.parse(req.body.toString());
        const notificationType = notification.notificationType;
        const data = notification.data;

        if (!data || !data.signedTransactionInfo) {
            return res.status(400).json({ error: 'Invalid notification data' });
        }

        const transactionInfo = data.signedTransactionInfo;
        const decodedTransaction = JSON.parse(Buffer.from(transactionInfo.split('.')[1], 'base64').toString());
        
        const originalTransactionId = decodedTransaction.originalTransactionId;
        const transactionKey = `${originalTransactionId}-${notificationType}`;

        if (processedTransactions.has(transactionKey)) {
            console.log(`Already processed transaction: ${transactionKey}`);
            return res.status(200).json({ success: true, message: 'Already processed' });
        }

        const appleSub = decodedTransaction.appAccountToken;
        if (!appleSub) {
            console.error('No app account token in transaction');
            return res.status(400).json({ error: 'Missing app account token' });
        }

        const { data: user, error: userError } = await supabase
            .from('users')
            .select('id')
            .eq('apple_sub', appleSub)
            .single();

        if (userError || !user) {
            console.error('User not found for Apple sub:', appleSub);
            return res.status(404).json({ error: 'User not found' });
        }

        let isActive = false;
        let renewsAt = null;

        switch (notificationType) {
            case 'SUBSCRIBED':
            case 'DID_RENEW':
            case 'DID_CHANGE_RENEWAL_STATUS':
                isActive = true;
                if (decodedTransaction.expiresDate) {
                    renewsAt = new Date(decodedTransaction.expiresDate);
                }
                break;
            
            case 'EXPIRED':
            case 'REFUND':
            case 'REVOKE':
                isActive = false;
                break;
            
            default:
                console.log(`Unhandled notification type: ${notificationType}`);
                return res.status(200).json({ success: true, message: 'Notification type not handled' });
        }

        const { error: updateError } = await supabase
            .from('entitlements')
            .upsert({
                user_id: user.id,
                is_active: isActive,
                product_id: decodedTransaction.productId,
                renews_at: renewsAt,
                updated_at: new Date().toISOString()
            });

        if (updateError) {
            console.error('Error updating entitlements:', updateError);
            return res.status(500).json({ error: 'Failed to update entitlements' });
        }

        processedTransactions.add(transactionKey);

        console.log(`Processed ${notificationType} for user ${user.id}, active: ${isActive}`);
        res.status(200).json({ success: true });

    } catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
});

module.exports = router;
