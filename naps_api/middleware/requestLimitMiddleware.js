const attempts = new Map();

exports.authRequestLimit = (req, res, next) => {
  const now = Date.now();
  if (attempts.size > 10000) {
    for (const [address, value] of attempts) {
      if (now - value.startedAt > 15 * 60 * 1000) attempts.delete(address);
    }
  }
  const key = req.ip;
  const current = attempts.get(key);
  if (!current || now - current.startedAt > 15 * 60 * 1000) {
    attempts.set(key, { startedAt: now, count: 1 });
    return next();
  }
  if (current.count >= 20) return res.status(429).json({ message: 'too many sign in attempts; try again later' });
  current.count += 1;
  next();
};
