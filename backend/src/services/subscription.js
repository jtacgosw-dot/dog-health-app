const supabase = require('./supabase');

/**
 * Verify App Store receipt and update subscription status
 * @param {string} receiptData - Base64 encoded receipt data
 * @param {string} userId - User ID
 * @returns {Promise<object>} Subscription status
 */
async function verifyReceipt(receiptData, userId) {
  try {
    const isProduction = process.env.NODE_ENV === 'production';
    const verifyUrl = isProduction
      ? 'https://buy.itunes.apple.com/verifyReceipt'
      : 'https://sandbox.itunes.apple.com/verifyReceipt';

    const response = await fetch(verifyUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        'receipt-data': receiptData,
        'password': process.env.APPLE_SHARED_SECRET,
        'exclude-old-transactions': true
      })
    });

    const receiptResponse = await response.json();

    if (receiptResponse.status !== 0) {
      if (receiptResponse.status === 21007 && isProduction) {
        return verifyReceipt(receiptData, userId); // Retry with sandbox
      }
      throw new Error(`Receipt verification failed with status: ${receiptResponse.status}`);
    }

    const latestReceiptInfo = receiptResponse.latest_receipt_info?.[0];
    if (!latestReceiptInfo) {
      throw new Error('No receipt info found');
    }

    const productId = latestReceiptInfo.product_id;
    const transactionId = latestReceiptInfo.transaction_id;
    const originalTransactionId = latestReceiptInfo.original_transaction_id;
    const purchaseDate = new Date(parseInt(latestReceiptInfo.purchase_date_ms));
    const expiresDate = latestReceiptInfo.expires_date_ms
      ? new Date(parseInt(latestReceiptInfo.expires_date_ms))
      : null;
    const isTrial = latestReceiptInfo.is_trial_period === 'true';

    const { data: existingSubscription } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('transaction_id', transactionId)
      .single();

    if (existingSubscription) {
      const { error: updateError } = await supabase
        .from('subscriptions')
        .update({
          expires_date: expiresDate,
          is_active: expiresDate ? expiresDate > new Date() : true,
          receipt_data: receiptResponse,
          updated_at: new Date().toISOString()
        })
        .eq('id', existingSubscription.id);

      if (updateError) {
        throw new Error('Failed to update subscription');
      }
    } else {
      const { error: insertError } = await supabase
        .from('subscriptions')
        .insert([{
          user_id: userId,
          product_id: productId,
          transaction_id: transactionId,
          original_transaction_id: originalTransactionId,
          purchase_date: purchaseDate,
          expires_date: expiresDate,
          is_trial: isTrial,
          is_active: expiresDate ? expiresDate > new Date() : true,
          receipt_data: receiptResponse
        }]);

      if (insertError) {
        throw new Error('Failed to create subscription record');
      }
    }

    const subscriptionStatus = productId === 'pup_monthly' ? 'pup_monthly' : 'pup_annual';
    const { error: userUpdateError } = await supabase
      .from('users')
      .update({
        subscription_status: subscriptionStatus,
        subscription_expires_at: expiresDate
      })
      .eq('id', userId);

    if (userUpdateError) {
      throw new Error('Failed to update user subscription status');
    }

    return {
      success: true,
      subscription: {
        productId,
        expiresDate,
        isActive: expiresDate ? expiresDate > new Date() : true,
        isTrial
      }
    };
  } catch (error) {
    console.error('Receipt verification error:', error);
    throw error;
  }
}

/**
 * Check user's subscription status
 * @param {string} userId - User ID
 * @returns {Promise<object>} Subscription status
 */
async function checkSubscriptionStatus(userId) {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('subscription_status, subscription_expires_at')
      .eq('id', userId)
      .single();

    if (error) {
      throw new Error('Failed to fetch user subscription status');
    }

    const isSubscribed = user.subscription_status !== 'free';
    const isExpired = user.subscription_expires_at
      ? new Date(user.subscription_expires_at) < new Date()
      : false;

    return {
      isSubscribed: isSubscribed && !isExpired,
      subscriptionType: user.subscription_status,
      expiresAt: user.subscription_expires_at
    };
  } catch (error) {
    console.error('Subscription status check error:', error);
    throw error;
  }
}

module.exports = {
  verifyReceipt,
  checkSubscriptionStatus
};
