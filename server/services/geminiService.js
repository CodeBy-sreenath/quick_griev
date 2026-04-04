// server/services/groqService.js

import Groq from "groq-sdk";

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export const analyzeComplaint = async (complaintText) => {

  const prompt = `
You are an AI system for government complaint prioritization.

The complaint may be in English or Malayalam.

PRIORITY RULES:

HIGH:
English keywords: accident, injured, death, fire, emergency, hospital, ambulance
Malayalam keywords: അപകടം, പരിക്ക്, മരണം, തീപിടിത്തം, അടിയന്തര, ആശുപത്രി, ആംബുലൻസ്

MEDIUM:
English keywords: electricity issue, water problem, road damage, traffic jam
Malayalam keywords: വൈദ്യുതി, വെള്ളം, റോഡ് കേടായി, ഗതാഗതക്കുരുക്ക്

LOW:
English keywords: garbage, cleanliness, noise, stray animals
Malayalam keywords: മാലിന്യം, ശുചിത്വം, ശബ്ദം, തെരുവ് നായ

DEPARTMENT RULES:

Police:
English: crime, theft, violence
Malayalam: കുറ്റകൃത്യം, മോഷണം, ആക്രമണം, പോലീസ്

Health:
English: hospital, injury, ambulance
Malayalam: ആശുപത്രി, പരിക്ക്, ആംബുലൻസ്

Electricity:
English: power, transformer, electric post, electric shock, power cut
Malayalam: വൈദ്യുതി, ട്രാൻസ്ഫോർമർ, ഇലക്ട്രിക് പോസ്റ്റ്, കറന്റ് ഷോക്ക്,തെരുവ് ലൈറ്റ്

Water:
English: water supply, pipeline, leakage
Malayalam: വെള്ളം, പൈപ്പ്, ചോർച്ച,വെള്ളം, വെള്ളവിതരണം, ജലവിതരണം, പൈപ്പ്, ചോർച്ച, വെള്ളക്കുറവ്

Transport:
English: road, traffic, accident
Malayalam: റോഡ്, ഗതാഗതം, അപകടം

Municipality:
English: garbage, cleanliness, waste
Malayalam: മാലിന്യം, ശുചിത്വം, മാലിന്യ ശേഖരണം

Complaint:
"${complaintText}"

Respond ONLY in JSON:
{"priority":"high","department":"Transport"}
`;

  try {
    const response = await groq.chat.completions.create({
      model: "llama3-70b-8192",
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
      temperature: 0, // deterministic output
    });

    if (
      !response.choices?.length ||
      !response.choices[0]?.message?.content
    ) {
      console.error("Invalid Groq response:", response);
      return fallbackAnalysis(complaintText, true);
    }

    const text = response.choices[0].message.content
      .replace(/```json|```/g, "")
      .trim();

    let result;

    try {
      result = JSON.parse(text);
    } catch (parseError) {
      console.error("JSON Parse Error:", parseError.message);
      return fallbackAnalysis(complaintText, true);
    }

    return {
      priority: result.priority?.toLowerCase() || "low",
      department: result.department || "Municipality",
      message: "✅ AI analyzed successfully"
    };

  } catch (err) {
    console.error("Groq error:", err.message);
    return fallbackAnalysis(complaintText, true);
  }
};


// 🔁 FALLBACK NLP (ALWAYS SAFE)
const fallbackAnalysis = (text, aiFailed = false) => {
  text = text.toLowerCase();

  let priority = "low";
  let department = "Municipality";

  if (
    text.includes("accident") ||
    text.includes("injured") ||
    text.includes("emergency") ||
    text.includes("അപകടം") ||
    text.includes("പരിക്ക്") ||
    text.includes("അടിയന്തര")
  ) {
    priority = "high";
    department = "Transport";
  } 
  else if (
    text.includes("electricity") ||
    text.includes("water") ||
    text.includes("traffic") ||
    text.includes("വൈദ്യുതി") ||
    text.includes("വെള്ളം") ||
    text.includes("ഗതാഗതം")
  ) {
    priority = "medium";

    if (text.includes("electricity") || text.includes("വൈദ്യുതി")|| text.includes("തെരുവ് ലൈറ്റ്"))
      
      department = "Electricity";
    else if (text.includes("water") || text.includes("വെള്ളം")||
    text.includes("ജലവിതരണം")||
    text.includes(" പൈപ്പ്")||
    text.includes("വെള്ളക്കുറവ്")||
    text.includes("ചോർച്ച"))
      department = "Water";
    else if (
      text.includes("traffic") ||
      text.includes("road") ||
      text.includes("ഗതാഗതം") ||
      text.includes("റോഡ്")
    )
      department = "Transport";
  } 
  else if (
    text.includes("crime") ||
    text.includes("theft") ||
    text.includes("violence") ||
    text.includes("കുറ്റകൃത്യം") ||
    text.includes("മോഷണം") ||
    text.includes("ആക്രമണം")
  ) {
    priority = "high";
    department = "Police";
  } 
  else if (
    text.includes("hospital") ||
    text.includes("injury") ||
    text.includes("ambulance") ||
    text.includes("ആശുപത്രി") ||
    text.includes("ആംബുലൻസ്")
  ) {
    priority = "high";
    department = "Health";
  }

  console.log("✅ Using fallback:", { priority, department });

  return {
    priority,
    department,
    message: aiFailed
      ? "⚠️ AI analysis failed, using fallback analysis"
      : "✅ Fallback analysis used"
  };
};