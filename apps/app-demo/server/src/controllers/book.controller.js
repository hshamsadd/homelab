// Controllers handle HTTP-specific concerns (status codes, response format, headers, errors)
import * as bookService from '../services/book.service.js';
import { sendResponse } from '../utils/response.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const getBooks = asyncHandler(async (req, res) => {
  const books = await bookService.getAllBooks();
  const meta = { total: books.length }; // Optional only business metadata
  return sendResponse(res, books, 'Books fetched successfully', 200, meta);
});

export const getBook = asyncHandler(async (req, res) => {
  const book = await bookService.getBookById(req.params.id);
  const meta = {}; // You don’t need meta = {} in getBook unless you actually have business metadata. You can remove it:
  return sendResponse(res, book, 'Book fetched successfully', 200, meta);
});

export const createBook = asyncHandler(async (req, res) => {
  const newBook = await bookService.createBook(req.body);
  return sendResponse(res, newBook, 'Book created successfully', 201);
});

export const updateBook = asyncHandler(async (req, res) => {
  // PUT / full replacement
  const updatedBook = await bookService.replaceBookById(req.params.id, req.body);
  return sendResponse(res, updatedBook, 'Book updated successfully', 200);
});

export const patchBook = asyncHandler(async (req, res) => {
  // PATCH / partial update
  const updatedBook = await bookService.updateBookById(req.params.id, req.body);
  return sendResponse(res, updatedBook, 'Book updated successfully', 200);
});

export const deleteBook = asyncHandler(async (req, res) => {
  const deletedBook = await bookService.deleteBookById(req.params.id);
  return sendResponse(res, deletedBook, 'Book deleted successfully', 200);
});
