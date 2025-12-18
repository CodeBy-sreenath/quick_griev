import bcrypt from "bcryptjs";
import crypto from "crypto";
import { sendOtpEmail } from "./utils/sendEmail.js";
import User from "./model/user.js";

// ---------------- REGISTER ----------------
export const registerUser = async (req, res) => {
  try {
    console.log("📥 Register endpoint hit");
    console.log("Body received:", req.body);

    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({
        message: "Request body is empty. Ensure Content-Type is application/json",
      });
    }

    const { name, username, email, password } = req.body;

    if (!name || !username || !email || !password) {
      return res.status(400).json({
        message: "All fields are required",
      });
    }

    // Check if user exists
    const userExists = await User.findOne({
      $or: [{ email }, { username }],
    });

    if (userExists) {
      return res.status(400).json({ message: "User already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const emailOtp = crypto.randomInt(100000, 999999).toString();

    const newUser = new User({
      name,
      username,
      email,
      password: hashedPassword,
      emailOtp,
      emailOtpExpires: new Date(Date.now() + 5 * 60 * 1000),
      isEmailVerified: false,
      isVerified: false,
    });

    await newUser.save();
    console.log("✅ User saved");

    // Send Email OTP
    try {
      await sendOtpEmail(email, emailOtp);
      console.log("✅ Email OTP sent");
    } catch (err) {
      console.error("⚠️ Email sending failed:", err.message);
      return res.status(500).json({
        message: "User created but failed to send OTP. Try again.",
        userId: newUser._id,
      });
    }

    res.status(201).json({
      message: "User registered. OTP sent to email.",
      userId: newUser._id,
      verificationRequired: {
        email: true,
      },
    });
  } catch (error) {
    console.error("❌ Register error:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
};

// ---------------- VERIFY EMAIL OTP ----------------
export const verifyEmailOtp = async (req, res) => {
  try {
    console.log("📥 Verify Email OTP endpoint hit");
    console.log("Body:", req.body);

    const { userId, otp } = req.body;

    if (!userId || !otp) {
      return res.status(400).json({ message: "UserId and OTP are required" });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email already verified" });
    }

    if (user.emailOtp !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.emailOtpExpires < new Date()) {
      return res.status(400).json({ message: "OTP expired" });
    }

    user.isEmailVerified = true;
    user.emailOtp = null;
    user.emailOtpExpires = null;
    user.isVerified = true;

    await user.save();

    res.json({
      message: "Email verified successfully",
      fullyVerified: true,
    });
  } catch (error) {
    console.error("❌ Verify Email OTP error:", error);
    res.status(500).json({ message: "Email OTP verification failed" });
  }
};

// ---------------- RESEND EMAIL OTP ----------------
export const resendEmailOtp = async (req, res) => {
  try {
    console.log("📥 Resend Email OTP");

    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "UserId is required" });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: "Email already verified" });
    }

    const emailOtp = crypto.randomInt(100000, 999999).toString();
    user.emailOtp = emailOtp;
    user.emailOtpExpires = new Date(Date.now() + 5 * 60 * 1000);
    await user.save();

    await sendOtpEmail(user.email, emailOtp);

    res.json({ message: "Email OTP resent successfully" });
  } catch (error) {
    console.error("❌ Resend Email OTP error:", error);
    res.status(500).json({ message: "Failed to resend email OTP" });
  }
};

// ---------------- LOGIN ----------------
export const loginUser = async (req, res) => {
  try {
    console.log("📥 Login endpoint hit");
    console.log("Body:", req.body);

    const { username, email, password } = req.body;

    if ((!username && !email) || !password) {
      return res.status(400).json({ message: "Missing login fields" });
    }

    const user = await User.findOne({
      $or: [{ username }, { email }],
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(400).json({ message: "Invalid credentials" });
    }

    if (!user.isVerified) {
      return res.status(401).json({
        message: "Email not verified",
        userId: user._id,
      });
    }

    // Generate Login OTP
    const emailOtp = crypto.randomInt(100000, 999999).toString();
    user.emailOtp = emailOtp;
    user.emailOtpExpires = new Date(Date.now() + 5 * 60 * 1000);

    await sendOtpEmail(user.email, emailOtp);
    await user.save();

    res.json({
      message: "Login OTP sent to your email",
      userId: user._id,
    });
  } catch (error) {
    console.error("❌ Login error:", error);
    res.status(500).json({ message: "Login failed" });
  }
};

// ---------------- VERIFY LOGIN OTP ----------------
export const verifyLoginOtp = async (req, res) => {
  try {
    const { userId, otp } = req.body;

    if (!userId || !otp) {
      return res.status(400).json({ message: "UserId and OTP are required" });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (user.emailOtp !== otp) {
      return res.status(400).json({ message: "Invalid OTP" });
    }

    if (user.emailOtpExpires < new Date()) {
      return res.status(400).json({ message: "OTP expired" });
    }

    user.emailOtp = null;
    user.emailOtpExpires = null;
    await user.save();

    res.json({
      message: "Login successful",
      user: {
        id: user._id,
        name: user.name,
        username: user.username,
        email: user.email,
      },
    });
  } catch (error) {
    console.error("❌ Verify Login OTP error:", error);
    res.status(500).json({ message: "OTP verification failed" });
  }
};
