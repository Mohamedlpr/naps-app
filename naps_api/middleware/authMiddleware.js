const jwt = require('jsonwebtoken');
const User = require('../models/userModel');

exports.tokenVerification = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ message: 'please sign in to continue' });
    const decoded = jwt.verify(token, process.env.JWT_SECRET, { algorithms: ['HS256'] });
    const user = await User.findOne({ _id: decoded.sub, organization: decoded.org, active: true });
    if (!user) return res.status(401).json({ message: 'your account is inactive or no longer exists' });
    req.user = { id: user.id, organization: user.organization.toString(), name: user.name, role: user.role, branch: user.branch };
    next();
  } catch (err) {
    next(err);
  }
};

exports.requireRoles = (...roles) => (req, res, next) => {
  if (!roles.includes(req.user.role)) return res.status(403).json({ message: 'you do not have permission to perform this action' });
  next();
};
