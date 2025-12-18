import express from 'express'
import { createComplaint } from '../controller/complaintController.js'
const complaintRouter=express.Router()
complaintRouter.post("/user-complaint",createComplaint)
export default complaintRouter