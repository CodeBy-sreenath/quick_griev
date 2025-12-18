//import Complaint from "../models/complaintModel.js";
import Complaint from "../model/complaint.js";
import { analyzeComplaint } from "../services/geminiService.js";

export const createComplaint = async (req, res) => {
  try {
    const {
      userId,
      complaintText,
      language,
      imageUrl,
      voiceText,
      location
    } = req.body;

    // 1️⃣ Store complaint initially
    const complaint = await Complaint.create({
      userId,
      complaintText,
      language,
      imageUrl,
      voiceText,
      location
    });

    // 2️⃣ AI analysis
    const aiResult = await analyzeComplaint(complaintText);

    // 3️⃣ Update complaint with AI result
    complaint.priority = aiResult.priority;
    complaint.department = aiResult.department;
    await complaint.save();

    res.status(201).json({
      success: true,
      message: "Complaint registered successfully",
      complaint
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message
    });
  }
};
