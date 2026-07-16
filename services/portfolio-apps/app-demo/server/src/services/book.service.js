// Business logic
import Book from '../models/book.model.js'; // ✅ include .js
import { ApiError } from '../utils/apiError.js';

// Get all books (with optional filters/pagination query)
export const getAllBooks = async (query) => {
  const books = await Book.find(query); // apply filters/pagination if needed
  if (!books || books.length === 0) {
    throw new ApiError(404, 'No books found');
  }
  return books;
};

// Get one book by ID
export const getBookById = async (bookId) => {
  const book = await Book.findById(bookId);
  if (!book) {
    throw new ApiError(404, 'Book not found');
  }
  return book;
};

// Create a new book
export const createBook = async (bookData) => {
  const newBook = await Book.create(bookData);
  return newBook;
};

// PATCH / partial update
export const updateBookById = async (bookId, updateData) => {
  const book = await Book.findById(bookId);
  if (!book) {
    throw new ApiError(404, 'Book not found');
  }
  // Only update fields provided
  Object.keys(updateData).forEach((key) => {
    book[key] = updateData[key];
  });

  await book.save();
  return book;
};

// PUT / full replacement
export const replaceBookById = async (bookId, newBookData) => {
  const book = await Book.findById(bookId);
  if (!book) {
    throw new ApiError(404, 'Book not found');
  }
  // Overwrite all fields except _id
  Object.keys(book.toObject()).forEach((key) => {
    if (key !== '_id') {
      book[key] = newBookData[key];
    }
  });
  await book.save();
  return book;
};

// Delete a book by ID
export const deleteBookById = async (bookId) => {
  const book = await Book.findByIdAndDelete(bookId);
  if (!book) {
    throw new ApiError(404, 'Book not found');
  }
  return book;
};
