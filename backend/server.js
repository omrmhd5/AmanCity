const app = require('./app');
const mongoose = require('mongoose');
const PORT = process.env.PORT || 5000;

// MongoDB Connection
// const connectDB = async () => {
//   try {
//     await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/amancity');
//     console.log('MongoDB connected successfully');
//   } catch (error) {
//     console.error('MongoDB connection error:', error.message);
//     process.exit(1);
//   }
// };

// connectDB();

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Connected to MongoDB`);
});
