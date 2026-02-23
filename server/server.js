import express from 'express'
import 'dotenv/config'
import cors from 'cors'
import connectDB from './config/db.js'
import userRouter from './routes/userRoute.js'
import complaintRouter from './routes/complaintRoute.js'
import adminRouter from './routes/adminAuthRoute.js'
import statusrouter from './routes/statusRoute.js'

const app = express()
const PORT = process.env.PORT || 3000

// ✅ FIXED CORS CONFIGURATION - This solves the Flutter Web CORS issue
const corsOptions = {
  origin: '*', // Allow all origins for development
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH', 'HEAD'],
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'Accept',
    'Origin',
    'X-Requested-With',
    'Access-Control-Request-Method',
    'Access-Control-Request-Headers'
  ],
  exposedHeaders: ['Content-Length', 'Content-Type'],
  credentials: true,
  maxAge: 86400, // Cache preflight request for 24 hours
  preflightContinue: false,
  optionsSuccessStatus: 204
}

// Apply CORS middleware
app.use(cors(corsOptions))

// ✅ Additional CORS headers as backup (for extra safety)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Credentials', 'true')
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS, PATCH, HEAD')
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, Origin, X-Requested-With')
  
  // Handle preflight OPTIONS requests
  if (req.method === 'OPTIONS') {
    return res.status(204).end()
  }
  
  next()
})

// Express middleware configuration
app.use(express.json({ strict: false }))
app.use(express.urlencoded({ extended: true }))

// ✅ Debugging middleware to check if body is being parsed
app.use((req, res, next) => {
  console.log('Request Method:', req.method)
  console.log('Request URL:', req.url)
  console.log('Content-Type:', req.get('Content-Type'))
  console.log('Origin:', req.get('Origin'))
  console.log('Request Body:', req.body)
  next()
})

// Routes
app.get('/', (req, res) => {
  res.send("Server is running")
})

app.use("/api/users", userRouter)
app.use("/api/complaint",complaintRouter)
app.use("/api/admin",adminRouter)
app.use("/api/status",statusrouter)
app.use("/uploads", express.static("uploads"));


// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Error:', err)
  res.status(500).json({ message: 'Internal server error', error: err.message })
})

// Connect to database and start server
connectDB()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`✅ Server is running on http://localhost:${PORT}`)
      console.log(`✅ CORS enabled for all origins`)
    })
  })
  .catch((error) => {
    console.error("❌ Database connection failed:", error)
    process.exit(1);
  })