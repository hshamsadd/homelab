import mongoose from 'mongoose';

const connectToDb = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('Mongodb is connected successfully.');
  } catch (err) {
    console.error('Mongodb connection failed.', err);
    process.exit(1);
  }
};

export default connectToDb;
