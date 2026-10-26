const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
  organization: { type: mongoose.Schema.Types.ObjectId, ref: 'Organization', required: true, immutable: true, index: true },
  title: { type: String, required: true, trim: true, minlength: 3, maxlength: 160 },
  message: { type: String, required: true, trim: true, minlength: 3, maxlength: 5000 },
  branch: { type: String, required: true, trim: true, maxlength: 100 },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, immutable: true },
  acknowledgedBy: [{ user: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, acknowledgedAt: { type: Date, default: Date.now } }],
}, { timestamps: true });

announcementSchema.index({ organization: 1, branch: 1, createdAt: -1 });

module.exports = mongoose.model('Announcement', announcementSchema);
