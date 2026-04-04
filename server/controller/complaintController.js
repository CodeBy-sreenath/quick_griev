import Complaint from "../model/complaint.js";
import Status from "../model/status.js";
import { analyzeComplaint } from "../services/groqService.js";

// ✅ VALIDATION FUNCTION - Lightweight pre-filter before hitting AI
const isValidComplaint = (text) => {
  const cleanText = text.trim().toLowerCase();
  const hasMalayalam = /[\u0D00-\u0D7F]/.test(cleanText);

  if (cleanText.length < 10) {
    return { valid: false, reason: "Complaint is too short. Please provide more details." };
  }

  const words = cleanText.split(/\s+/).filter(word => word.length > 0);
  if (words.length < 3) {
    return { valid: false, reason: "Complaint must contain at least 3 words." };
  }

  const repeatedPattern = /(.)\1{4,}/;
  if (repeatedPattern.test(cleanText)) {
    return { valid: false, reason: "Invalid complaint text detected. Please write a meaningful complaint." };
  }

  const alphabeticChars = cleanText.match(/[a-zA-Z\u0D00-\u0D7F]/g) || [];
  const totalChars = cleanText.replace(/\s/g, '').length;
  if (alphabeticChars.length < totalChars * 0.5) {
    return { valid: false, reason: "Complaint must contain meaningful text." };
  }

  if (!hasMalayalam) {
    const hasVowels = /[aeiouAEIOU]/;
    const wordChunks = cleanText.split(/\s+/);
    let meaningfulWords = 0;
    for (const word of wordChunks) {
      if (word.length >= 2 && hasVowels.test(word)) meaningfulWords++;
    }
    if (meaningfulWords < Math.ceil(words.length * 0.5)) {
      return { valid: false, reason: "Complaint does not appear to be meaningful. Please describe your issue clearly." };
    }
  }

  const wordArray = cleanText.split(/\s+/);
  const wordCount = {};
  for (const word of wordArray) {
    if (word.length > 1) wordCount[word] = (wordCount[word] || 0) + 1;
  }

  const totalWords = wordArray.length;
  for (const [, count] of Object.entries(wordCount)) {
    if (count / totalWords > 0.4 && totalWords >= 3) {
      return { valid: false, reason: "Complaint contains too many repeated words. Please write a clear description." };
    }
  }

  for (let i = 0; i < wordArray.length - 1; i++) {
    if (wordArray[i].length > 1 && wordArray[i] === wordArray[i + 1]) {
      let repeatCount = 1;
      for (let j = i + 1; j < wordArray.length && wordArray[i] === wordArray[j]; j++) repeatCount++;
      if (repeatCount >= 2) {
        return { valid: false, reason: "Complaint contains repeated words. Please provide a proper description." };
      }
    }
  }

  const spamPatterns = [
    /^test$/i,
    /^testing$/i,
    /^(.)(\1)+$/,
    /^(..)\1+$/,
  ];
  for (const pattern of spamPatterns) {
    if (pattern.test(cleanText)) {
      return { valid: false, reason: "Invalid complaint format. Please provide a real complaint." };
    }
  }

  return { valid: true };
};

// ✅ CHECK 5 COMPLAINTS PER USER PER DAY
const checkDailyLimit = async (userId) => {
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const endOfDay = new Date();
  endOfDay.setHours(23, 59, 59, 999);

  const todayCount = await Complaint.countDocuments({
    userId,
    createdAt: { $gte: startOfDay, $lte: endOfDay },
  });

  return todayCount;
};

export const createComplaint = async (req, res) => {
  try {
    const { userId, complaintText, language, voiceText, location } = req.body;

    let imageUrl = null;
    if (req.file) imageUrl = `/uploads/${req.file.filename}`;

    // ✅ STEP 1: Rule-based pre-filter (no AI cost)
    const validation = isValidComplaint(complaintText);
    if (!validation.valid) {
      return res.status(400).json({ success: false, message: validation.reason });
    }

    // ✅ STEP 2: Check daily complaint limit (5 per day)
    const todayCount = await checkDailyLimit(userId);
    if (todayCount >= 5) {
      return res.status(429).json({
        success: false,
        message: "You have reached the daily limit of 5 complaints. Please try again tomorrow.",
      });
    }

    // ✅ STEP 3: Save complaint with safe defaults first
    const complaint = await Complaint.create({
      userId,
      complaintText,
      language,
      imageUrl,
      voiceText,
      location,
      department: "Municipality",
      priority: "low",
    });

    // ✅ STEP 4: AI analysis — fake detection + classification
    try {
      const aiResult = await analyzeComplaint(complaintText);

      // 🚫 AI says it's fake — delete and reject
      if (aiResult?.isFake === true) {
        await Complaint.findByIdAndDelete(complaint._id);
        return res.status(400).json({
          success: false,
          message: aiResult.fakeReason || "Your complaint does not appear to be a real civic issue. Please describe a genuine problem.",
        });
      }

      // ✅ Real complaint — update with AI classification
      if (aiResult?.department) complaint.department = aiResult.department;
      if (aiResult?.priority) complaint.priority = aiResult.priority;
      await complaint.save();

    } catch (aiError) {
      console.error("AI failed, saved with defaults:", aiError.message);
      // ❗ AI failure never blocks the user — complaint kept with defaults
    }

    res.status(201).json({
      success: true,
      message: "Complaint registered successfully",
      complaint,
    });

  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUserComplaints = async (req, res) => {
  try {
    const { userId } = req.params;
    const complaints = await Complaint.find({ userId }).sort({ createdAt: -1 });
    res.json({ success: true, complaints });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getDepartmentComplaints = async (req, res) => {
  try {
    const { department } = req.params;

    const complaints = await Complaint.aggregate([
      { $match: { department } },
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
      { $sort: { priorityOrder: 1, createdAt: -1 } },
    ]);

    res.json({ success: true, complaints });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getComplaintUpdates = async (req, res) => {
  try {
    const { complaintId } = req.params;
    const updates = await Status.find({ complaintId }).sort({ createdAt: 1 });
    res.status(200).json({ success: true, updates });
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to fetch updates" });
  }
};