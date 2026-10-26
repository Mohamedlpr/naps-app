const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  organization: { type: mongoose.Schema.Types.ObjectId, ref: 'Organization', required: true, immutable: true, index: true },
  title: { type: String, required: true, trim: true, minlength: 2, maxlength: 160 },
  details: { type: String, trim: true, maxlength: 4000, default: '' },
  branch: { type: String, required: true, trim: true, maxlength: 100 },
  assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, immutable: true },
  dueDate: { type: Date, required: true },
  status: { type: String, enum: ['open', 'inProgress', 'complete'], default: 'open' },
}, { timestamps: true });

taskSchema.index({ organization: 1, branch: 1, dueDate: 1 });

module.exports = mongoose.model('Task', taskSchema);
