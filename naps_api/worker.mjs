import { httpServerHandler } from 'cloudflare:node';
import server from './server.js';
import connectDB from './DB/connect.js';

const { createApp } = server;

const connectDatabase = async (req, res, next) => {
  try {
    await connectDB();
    next();
  } catch (error) {
    next(error);
  }
};

const app = createApp({ beforeRoutes: connectDatabase });
app.listen(3000);

export default httpServerHandler({ port: 3000 });
