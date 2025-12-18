import express from "express";
import {
  registerUser,
  verifyEmailOtp,
  resendEmailOtp,
  loginUser,
  verifyLoginOtp,
} from "../authController.js";

const userRouter = express.Router();
userRouter.get("/", (req, res) => {
  res.json({ 
    message: "User API is working", 
    endpoints: {
      register: "POST /register",
      login: "POST /login",
      verifyEmail: "POST /verify-email-otp",
      verifyLogin: "POST /verify-login-otp",
      resendOtp: "POST /resend-email-otp"
    }
  });
});

// Registration
userRouter.post("/register", registerUser);
userRouter.post("/verify-email-otp", verifyEmailOtp);
userRouter.post("/resend-email-otp", resendEmailOtp);

// Login
userRouter.post("/login", loginUser);
userRouter.post("/verify-login-otp", verifyLoginOtp);

export default userRouter;
