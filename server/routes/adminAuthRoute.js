import express from "express"
import { adminLogin } from "../controller/adminAuthController.js"
const adminRouter=express.Router()
adminRouter.post("/login",adminLogin)
export default adminRouter