const express = require('express');
const { getTickets, createTicket, updateTicket, deleteTicket } = require('../controllers/ticketController');
const { tokenVerification } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(tokenVerification);
router.get('/', getTickets);
router.post('/', createTicket);
router.patch('/:id', updateTicket);
router.delete('/:id', deleteTicket);

module.exports = router;
