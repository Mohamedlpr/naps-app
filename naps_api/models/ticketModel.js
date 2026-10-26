const mongoose = require('mongoose');

const ticketSchema = new mongoose.Schema({
  organization: { type: mongoose.Schema.Types.ObjectId, ref: 'Organization', required: true, immutable: true, index: true },
  title: { type: String, required: true, trim: true, minlength: 3, maxlength: 160 },
  details: { type: String, trim: true, maxlength: 4000, default: '' },
  branch: { type: String, required: true, trim: true, maxlength: 100 },
  department: { type: String, required: true, trim: true, maxlength: 100 },
  status: { type: String, enum: ['open', 'progress', 'resolved'], default: 'open' },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, immutable: true },
  assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
}, { timestamps: true });

ticketSchema.index({ organization: 1, branch: 1, status: 1, createdAt: -1 });

module.exports = mongoose.model('Ticket', ticketSchema);
