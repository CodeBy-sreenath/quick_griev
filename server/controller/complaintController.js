import Complaint from "../model/complaint.js";
import Status from "../model/status.js";
import { analyzeComplaint } from "../services/geminiService.js";

// ✅ VALIDATION FUNCTION - Checks if complaint is meaningful
const isValidComplaint = (text) => {
  // Remove extra spaces and convert to lowercase
  const cleanText = text.trim().toLowerCase();
  
  
  const hasMalayalam = /[\u0D00-\u0D7F]/.test(cleanText);
  
  // 1. Check minimum length (at least 10 characters)
  if (cleanText.length < 10) {
    return { valid: false, reason: "Complaint is too short. Please provide more details." };
  }
  
  // 2. Check if text has at least 3 words
  const words = cleanText.split(/\s+/).filter(word => word.length > 0);
  if (words.length < 3) {
    return { valid: false, reason: "Complaint must contain at least 3 words." };
  }
  
  // 3. Check for gibberish (repeated characters like "aaaa", "bbbb")
  const repeatedPattern = /(.)\1{4,}/; 
  if (repeatedPattern.test(cleanText)) {
    return { valid: false, reason: "Invalid complaint text detected. Please write a meaningful complaint." };
  }
  
  // 4. Check if text contains mostly non-alphabetic characters
  const alphabeticChars = cleanText.match(/[a-zA-Z\u0D00-\u0D7F]/g) || []; // Include Malayalam unicode
  const totalChars = cleanText.replace(/\s/g, '').length;
  if (alphabeticChars.length < totalChars * 0.5) {
    return { valid: false, reason: "Complaint must contain meaningful text." };
  }
  
  // 5. Check for random keyboard mashing - SKIP FOR MALAYALAM
  if (!hasMalayalam) {
    const hasVowels = /[aeiouAEIOU]/; // English vowels only
    const wordChunks = cleanText.split(/\s+/);
    let meaningfulWords = 0;
    
    for (const word of wordChunks) {
      if (word.length >= 2 && hasVowels.test(word)) {
        meaningfulWords++;
      }
    }
    
    if (meaningfulWords < Math.ceil(words.length * 0.5)) {
      return { valid: false, reason: "Complaint does not appear to be meaningful. Please describe your issue clearly." };
    }
  }
  
  // 6. Check for repetitive words (e.g., "the the the", "hello hello")
  const wordArray = cleanText.split(/\s+/);
  const wordCount = {};
  
  // Count word occurrences
  for (const word of wordArray) {
    if (word.length > 1) { // Only count words longer than 1 character
      wordCount[word] = (wordCount[word] || 0) + 1;
    }
  }
  
  // Check if any word appears more than 40% of total words
  const totalWords = wordArray.length;
  for (const [word, count] of Object.entries(wordCount)) {
    const percentage = count / totalWords;
    if (percentage > 0.4 && totalWords >= 3) {
      return { valid: false, reason: "Complaint contains too many repeated words. Please write a clear description." };
    }
  }
  
  // Check for immediate word repetition (e.g., "the the", "hello hello hello")
  for (let i = 0; i < wordArray.length - 1; i++) {
    if (wordArray[i].length > 1 && wordArray[i] === wordArray[i + 1]) {
      // Check if same word repeats 2+ times consecutively
      let repeatCount = 1;
      for (let j = i + 1; j < wordArray.length && wordArray[i] === wordArray[j]; j++) {
        repeatCount++;
      }
      if (repeatCount >= 2) {
        return { valid: false, reason: "Complaint contains repeated words. Please provide a proper description." };
      }
    }
  }
  
  // 7. Check for common spam patterns
  const spamPatterns = [
    /^test$/i,
    /^testing$/i,
    /^(.)(\1)+$/,  // Single repeated character
    /^(..)\1+$/,   // Two characters repeated
  ];
  
  for (const pattern of spamPatterns) {
    if (pattern.test(cleanText)) {
      return { valid: false, reason: "Invalid complaint format. Please provide a real complaint." };
    }
  }
  
  return { valid: true };
};

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
    
    // ✅ VALIDATE COMPLAINT TEXT FIRST
    const validation = isValidComplaint(complaintText);
    if (!validation.valid) {
      return res.status(400).json({
        success: false,
        message: validation.reason,
      });
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

export const getComplaintUpdates = async (req, res) => {
  try {
    const { complaintId } = req.params;
    const updates = await Status.find({ complaintId }).sort({ createdAt: 1 });
    
    res.status(200).json({
      success: true,
      updates,
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch updates",
    });
  }
};