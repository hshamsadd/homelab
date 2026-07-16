export default [
  {
    files: ['**/*.js'], // only check .js files server directory
    rules: {
      semi: 'error', // force semicolons
      'no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    },
  },
];
