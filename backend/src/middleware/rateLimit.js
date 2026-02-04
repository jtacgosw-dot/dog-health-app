const rateLimit = (options = {}) => {
  const {
    windowMs = 60 * 1000, // 1 minute window
    maxRequests = 20, // max requests per window
    message = 'Too many requests, please try again later',
    keyGenerator = (req) => req.user?.id || req.ip // Use user ID if authenticated, otherwise IP
  } = options;

  // In-memory store for rate limiting
  const requests = new Map();

  // Cleanup old entries periodically
  setInterval(() => {
    const now = Date.now();
    for (const [key, data] of requests.entries()) {
      if (now - data.windowStart > windowMs) {
        requests.delete(key);
      }
    }
  }, windowMs);

  return (req, res, next) => {
    const key = keyGenerator(req);
    const now = Date.now();

    let requestData = requests.get(key);

    if (!requestData || now - requestData.windowStart > windowMs) {
      // Start a new window
      requestData = {
        windowStart: now,
        count: 1
      };
      requests.set(key, requestData);
      return next();
    }

    requestData.count++;

    if (requestData.count > maxRequests) {
      const retryAfter = Math.ceil((requestData.windowStart + windowMs - now) / 1000);
      res.set('Retry-After', retryAfter);
      return res.status(429).json({
        success: false,
        error: message,
        retryAfter
      });
    }

    next();
  };
};

// Pre-configured rate limiters for different endpoints
const chatRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 30, // 30 messages per minute
  message: 'Too many chat messages. Please wait a moment before sending more.'
});

const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 10, // 10 auth attempts per 15 minutes
  message: 'Too many authentication attempts. Please try again later.',
  keyGenerator: (req) => req.ip // Always use IP for auth
});

const generalRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  maxRequests: 100, // 100 requests per minute
  message: 'Too many requests. Please slow down.'
});

module.exports = {
  rateLimit,
  chatRateLimit,
  authRateLimit,
  generalRateLimit
};
