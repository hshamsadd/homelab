import express from 'express';
import {
  getBooks,
  getBook,
  createBook,
  updateBook,
  patchBook,
  deleteBook,
} from '../controllers/book.controller.js'; // ✅ include .js

// Create express router
const router = express.Router();

// Create all the routes that are related to books only
router.get('/', getBooks); // GET /books
router.get('/:id', getBook); // GET /books/:id
router.post('/', createBook); // POST /books
router.patch('/:id', patchBook); // PATCH /books/:id
router.put('/:id', updateBook); // PUT /books/:id
router.delete('/:id', deleteBook); // DELETE /books/:id

export default router; // ✅ default export
