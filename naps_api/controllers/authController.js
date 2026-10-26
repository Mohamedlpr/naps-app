const { promisify } = require('node:util');
const { randomBytes, scrypt: scryptCallback, timingSafeEqual } = require('node:crypto');
const jwt = require('jsonwebtoken');
const Organization = require('../models/organizationModel');
const User = require('../models/userModel');

const scrypt = promisify(scryptCallback);

const secretMatches = (provided, expected) => {
  if (typeof provided !== 'string' || typeof expected !== 'string') return false;
  const providedBuffer = Buffer.from(provided);
  const expectedBuffer = Buffer.from(expected);
  return providedBuffer.length === expectedBuffer.length && timingSafeEqual(providedBuffer, expectedBuffer);
};

const passwordHash = async (password) => {
  const salt = randomBytes(16).toString('hex');
  const derived = await scrypt(password, salt, 64);
  return `${salt}:${derived.toString('hex')}`;
};

const passwordMatches = async (password, storedHash) => {
  const [salt, key] = storedHash.split(':');
  const expected = Buffer.from(key, 'hex');
  const actual = await scrypt(password, salt, expected.length);
  return timingSafeEqual(expected, actual);
};

const createToken = (user) => jwt.sign(
  { sub: user.id, org: user.organization.toString() },
  process.env.JWT_SECRET,
  { algorithm: 'HS256', expiresIn: '8h' },
);

const publicUser = (user) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  role: user.role,
  branch: user.branch,
  phone: user.phone,
  organizationId: user.organization.toString(),
});

exports.bootstrapOrganization = async (req, res, next) => {
  try {
    const { setupSecret, organizationName, name, email, password, branch } = req.body;
    if (!secretMatches(setupSecret, process.env.BOOTSTRAP_SECRET)) {
      return res.status(403).json({ message: 'invalid organization setup code' });
    }
    if (await User.exists()) return res.status(409).json({ message: 'an administrator account already exists' });
    if (!organizationName?.trim() || !name?.trim() || !email?.trim() || !branch?.trim() || !password) {
      return res.status(400).json({ message: 'complete every required field' });
    }
    if (password.length < 12 || password.length > 128) return res.status(400).json({ message: 'the password must contain between 12 and 128 characters' });
    const organization = await Organization.findOneAndUpdate(
      { name: organizationName.trim() },
      { $setOnInsert: { name: organizationName.trim() } },
      { upsert: true, new: true, runValidators: true },
    );
    const user = await User.create({
      organization: organization.id,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      passwordHash: await passwordHash(password),
      role: 'admin',
      branch: branch.trim(),
    });
    return res.status(201).json({ token: createToken(user), user: publicUser(user) });
  } catch (err) {
    next(err);
  }
};

exports.login = async (req, res, next) => {
  try {
    const email = req.body.email?.trim().toLowerCase();
    const user = await User.findOne({ email, active: true }).select('+passwordHash');
    if (!user || !(await passwordMatches(req.body.password ?? '', user.passwordHash))) {
      return res.status(401).json({ message: 'email or password is incorrect' });
    }
    return res.json({ token: createToken(user), user: publicUser(user) });
  } catch (err) {
    next(err);
  }
};

exports.getSession = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'account not found' });
    return res.json(publicUser(user));
  } catch (err) {
    next(err);
  }
};

exports.changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;
    if (typeof newPassword !== 'string' || newPassword.length < 12 || newPassword.length > 128) return res.status(400).json({ message: 'the new password must contain between 12 and 128 characters' });
    const user = await User.findById(req.user.id).select('+passwordHash');
    if (!user || !(await passwordMatches(currentPassword ?? '', user.passwordHash))) return res.status(400).json({ message: 'the current password is incorrect' });
    user.passwordHash = await passwordHash(newPassword);
    await user.save();
    return res.json({ message: 'password changed successfully' });
  } catch (err) {
    next(err);
  }
};

exports.createPasswordHash = passwordHash;
exports.passwordMatches = passwordMatches;
