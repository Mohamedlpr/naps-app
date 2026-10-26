exports.errorHandling = (err, req, res, next) => {
  if (res.headersSent) return next(err);
  if (err.name === 'ValidationError' || err.name === 'CastError' || err.code === 11000) {
    return res.status(400).json({ message: err.code === 11000 ? 'this email is already registered' : err.message });
  }
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({ message: 'your session has expired; please sign in again' });
  }
  console.error(err);
  return res.status(500).json({ message: 'server error' });
};
