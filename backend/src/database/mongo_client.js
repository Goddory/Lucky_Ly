import mongoose from 'mongoose';

const connectMongo = async () => {
  try {
    const mongoUri = process.env.MONGO_URI;
    if (!mongoUri) {
      console.warn('⚠️ MONGO_URI is missing in .env. MongoDB will not be connected.');
      return;
    }
    
    await mongoose.connect(mongoUri);
    console.log('✅ Connected to MongoDB Desktop/Cloud successfully');
  } catch (error) {
    console.error('❌ MongoDB Connection Error:', error);
    // process.exit(1); 
  }
};

export default connectMongo;
