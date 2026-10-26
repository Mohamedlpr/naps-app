const User = require('../models/userModel');
const { createPasswordHash } = require('./authController');

exports.getUsers = async (req, res, next) => {
  try {
    const users = await User.find({ organization: req.user.organization, active: true }).select('name email role branch phone active').sort({ name: 1 });
    return res.json(users);
  } catch (err) { next(err); }
};

exports.createUser = async (req, res, next) => {
  try {
    const { name, email, password, role, branch, phone } = req.body;
    if (!name?.trim() || !email?.trim() || !password || !branch?.trim()) return res.status(400).json({ message: 'complete every required field' });
    if (password.length < 12 || password.length > 128) return res.status(400).json({ message: 'the password must contain between 12 and 128 characters' });
    const allowedRoles = req.user.role === 'admin' ? ['admin', 'supervisor', 'employee'] : ['supervisor', 'employee'];
    if (!allowedRoles.includes(role || 'employee')) return res.status(403).json({ message: 'you cannot assign this role' });
    const user = await User.create({ organization: req.user.organization, name: name.trim(), email: email.trim().toLowerCase(), passwordHash: await createPasswordHash(password), role: role || 'employee', branch: branch.trim(), phone: phone || '' });
    return res.status(201).json({ id: user.id, name: user.name, email: user.email, role: user.role, branch: user.branch, phone: user.phone, active: user.active });
  } catch (err) { next(err); }
};

exports.updateUser = async (req, res, next) => {
  try {
    const user = await User.findOne({ _id: req.params.id, organization: req.user.organization });
    if (!user) return res.status(404).json({ message: 'team member not found' });
    if (req.body.active === false && user.id === req.user.id) return res.status(400).json({ message: 'you cannot deactivate your own account' });
    if (req.user.role !== 'admin' && user.role === 'admin') return res.status(403).json({ message: 'only an administrator can change this account' });
    if (req.body.role !== undefined && !['admin', 'supervisor', 'employee'].includes(req.body.role)) return res.status(400).json({ message: 'choose a valid account role' });
    for (const field of ['name', 'branch', 'phone', 'active']) {
      if (req.body[field] !== undefined) user[field] = req.body[field];
    }
    if (req.user.role === 'admin' && req.body.role !== undefined) user.role = req.body.role;
    await user.save();
    return res.json({ id: user.id, name: user.name, email: user.email, role: user.role, branch: user.branch, phone: user.phone, active: user.active });
  } catch (err) { next(err); }
};
