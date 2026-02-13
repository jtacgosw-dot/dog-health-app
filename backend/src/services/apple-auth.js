const appleSignin = require('apple-signin-auth');
const jwt = require('jsonwebtoken');
const supabase = require('./supabase');

/**
 * Verify Apple Sign In token and create/update user
 * @param {string} identityToken - Apple identity token
 * @param {string} authorizationCode - Apple authorization code
 * @param {object} user - User info from Apple (optional)
 * @returns {Promise<object>} User data and JWT token
 */
async function verifyAppleToken(identityToken, authorizationCode, user = null) {
  try {
    const bundleId = 'com.johnathongordon.doghealthapp';
    const envClientId = process.env.APPLE_CLIENT_ID;
    const audiences = [bundleId];
    if (envClientId && envClientId !== bundleId) {
      audiences.unshift(envClientId);
    }

    let appleIdTokenClaims;
    let lastError;
    for (const aud of audiences) {
      try {
        appleIdTokenClaims = await appleSignin.verifyIdToken(identityToken, {
          audience: aud,
          ignoreExpiration: false
        });
        break;
      } catch (e) {
        lastError = e;
        console.log(`Apple token verification failed with audience "${aud}": ${e.message}`);
      }
    }
    if (!appleIdTokenClaims) {
      throw lastError || new Error('Apple token verification failed');
    }

    const appleUserId = appleIdTokenClaims.sub;
    const email = appleIdTokenClaims.email;

    const { data: existingUser, error: fetchError } = await supabase
      .from('users')
      .select('*')
      .eq('apple_user_id', appleUserId)
      .single();

    let userData;

    if (existingUser) {
      const { data: updatedUser, error: updateError } = await supabase
        .from('users')
        .update({ last_login_at: new Date().toISOString() })
        .eq('id', existingUser.id)
        .select()
        .single();

      if (updateError) {
        throw new Error('Failed to update user login time');
      }

      userData = updatedUser;
    } else {
      const newUser = {
        apple_user_id: appleUserId,
        apple_sub: appleUserId,
        email: email || null,
        full_name: user?.name ? `${user.name.firstName || ''} ${user.name.lastName || ''}`.trim() : null,
        subscription_status: 'free',
        last_login_at: new Date().toISOString()
      };

      const { data: createdUser, error: createError } = await supabase
        .from('users')
        .insert([newUser])
        .select()
        .single();

      if (createError) {
        throw new Error('Failed to create user');
      }

      userData = createdUser;
    }

    const jwtToken = jwt.sign(
      { userId: userData.id, appleUserId: appleUserId },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    return {
      user: userData,
      token: jwtToken
    };
  } catch (error) {
    console.error('Apple Sign In verification error:', error.message || error);
    throw error;
  }
}

module.exports = {
  verifyAppleToken
};
