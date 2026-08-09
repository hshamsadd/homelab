// Create a reusable asyncHandler utility. This automatically forwards any errors to your globalErrorHandler.
export const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
