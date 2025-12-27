import express from 'express'
import { adminComplaintStatus } from '../controller/complaintStatusController.js'
import { getComplaintUpdates } from '../controller/complaintController.js'
const statusrouter=express.Router()
statusrouter.post("/admin/complaints/:complaintId/status",adminComplaintStatus)
statusrouter.get( "/user/complaints/:complaintId/status",getComplaintUpdates)
export default statusrouter