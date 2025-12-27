//import Complaint from "../models/complaintModel.js";
import Complaint from "../model/complaint.js";
import Status from "../model/status.js";
import { analyzeComplaint } from "../services/geminiService.js";

export const createComplaint = async (req, res) => {
  try {
    const {
      userId,
      complaintText,
      language,
                           
      voiceText,
      location,
    } = req.body;
      let imageUrl = null;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    }
    

    // ✅ 1. SAVE complaint FIRST with SAFE defaults
    const complaint = await Complaint.create({
      userId,
      complaintText,
      language,
      imageUrl,
      voiceText,
      location,
      department: "Municipality", // ✅ REQUIRED DEFAULT
      priority: "low",            // ✅ REQUIRED DEFAULT
    });

    // ✅ 2. AI analysis (NON-BLOCKING LOGIC)
    try {
      const aiResult = await analyzeComplaint(complaintText);

      if (aiResult?.department) {
        complaint.department = aiResult.department;
      }
      if (aiResult?.priority) {
        complaint.priority = aiResult.priority;
      }

      await complaint.save();
    } catch (aiError) {
      console.error("AI failed, saved with defaults:", aiError.message);
      // ❗ DO NOT FAIL REQUEST
    }

    res.status(201).json({
      success: true,
      message: "Complaint registered successfully",
      complaint,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
export const getUserComplaints = async (req, res) => {
  try {
    const { userId } = req.params;

    const complaints = await Complaint.find({ userId })
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      complaints,
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getDepartmentComplaints = async (req, res) => {
  try {
    const { department } = req.params;

    const complaints = await Complaint.aggregate([
      {
        $match: { department },
      },
      {
        $addFields: {
          priorityOrder: {
            $switch: {
              branches: [
                { case: { $eq: ["$priority", "high"] }, then: 1 },
                { case: { $eq: ["$priority", "medium"] }, then: 2 },
                { case: { $eq: ["$priority", "low"] }, then: 3 },
              ],
              default: 4,
            },
          },
        },
      },
      {
        $sort: {
          priorityOrder: 1,   // 🔥 HIGH → MEDIUM → LOW
          createdAt: -1,      // newest first within same priority
        },
      },
    ]);

    res.json({
      success: true,
      complaints,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
export const getComplaintUpdates=async(req,res)=>{
  try
  {
    const{complaintId}=req.params
    const updates=await Status.find({complaintId}).sort({createdAt:1})
        res.status(200).json({
      success: true,
      updates,
    });


  }
  catch(error)
  {
      res.status(500).json({
      success: false,
      message: "Failed to fetch updates",
    });

  }
}

