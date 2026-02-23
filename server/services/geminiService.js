// server/services/geminiService.js

export const analyzeComplaint = async (complaintText) => {
  const prompt = `
You are an AI system for government complaint prioritization.

PRIORITY RULES:
- HIGH: accident, injured, death, fire, emergency, hospital, ambulance
- MEDIUM: electricity issue, water problem, road damage, traffic jam
- LOW: garbage, cleanliness, noise, stray animals

DEPARTMENT RULES:
- Police: crime, theft, violence
- Health: hospital, injury, ambulance
- Electricity: power, transformer,electric post,electric shock,accident,power cut
- Water: water supply, pipeline,leakage
- Transport: road, traffic, accident
- Municipality: garbage, cleanliness,waste    

Complaint:
"${complaintText}"

Respond ONLY in JSON:
{"priority":"high","department":"Transport"}
  `;

  try {
    // ✅ Use the correct v1beta endpoint and supported model
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-goog-api-key": process.env.GEMINI_API_KEY
        },
        body: JSON.stringify({
          contents: [
            {
              role: "user",
              parts: [{ text: prompt }]
            }
          ]
        })
      }
    );

    const data = await response.json();

    // ✅ Check for valid response
    if (!data.candidates?.length || !data.candidates[0]?.content?.parts?.[0]?.text) {
      console.error("Invalid Gemini response:", data);
      return fallbackAnalysis(complaintText, true); // AI failed
    }

    // ✅ Extract and parse JSON output from AI
    const text = data.candidates[0].content.parts[0].text
      .replace(/```json|```/g, "")
      .trim();

    const result = JSON.parse(text);

    return {
      priority: result.priority.toLowerCase(),
      department: result.department,
      message: "✅ AI analyzed successfully"
    };

  } catch (err) {
    console.error("Gemini error:", err.message);
    return fallbackAnalysis(complaintText, true); // AI failed
  }
};

// 🔁 FALLBACK NLP (ALWAYS SAFE)
const fallbackAnalysis = (text, aiFailed = false) => {
  text = text.toLowerCase();

  let priority = "low";
  let department = "Municipality";

  if (text.includes("accident") || text.includes("injured") || text.includes("emergency")) {
    priority = "high";
    department = "Transport";
  } else if (text.includes("electricity") || text.includes("water") || text.includes("traffic")) {
    priority = "medium";
    if (text.includes("electricity")) department = "Electricity";
    else if (text.includes("water")) department = "Water";
    else if (text.includes("traffic") || text.includes("road")) department = "Transport";
  } else if (text.includes("crime") || text.includes("theft") || text.includes("violence")) {
    priority = "high";
    department = "Police";
  } else if (text.includes("hospital") || text.includes("injury") || text.includes("ambulance")) {
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
