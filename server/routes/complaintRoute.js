import express from 'express'
import { createComplaint, getDepartmentComplaints, getUserComplaints } from '../controller/complaintController.js'
import { upload } from '../middleware/upload.js'
const complaintRouter=express.Router()
complaintRouter.post("/user-complaint",upload.single("image"),createComplaint)
complaintRouter.get("/department/:department",getDepartmentComplaints)
complaintRouter.get("/complaints/:userId",getUserComplaints)
export default complaintRouter