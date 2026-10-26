const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  organization: { type: mongoose.Schema.Types.ObjectId, ref: 'Organization', required: true, immutable: true },
  name: { type: String, required: true, trim: true, minlength: 2, maxlength: 80 },
  email: { type: String, required: true, trim: true, lowercase: true, maxlength: 160 },
  passwordHash: { type: String, required: true, select: false },
  role: { type: String, enum: ['admin', 'supervisor', 'employee'], default: 'employee' },
  branch: { type: String, required: true, trim: true, maxlength: 100 },
  phone: { type: String, trim: true, maxlength: 30, default: '' },
  active: { type: Boolean, default: true },
}, { timestamps: true });

userSchema.index({ organization: 1, email: 1 }, { unique: true });

module.exports = mongoose.model('User', userSchema);
