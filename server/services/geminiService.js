// server/services/groqService.js

import Groq from "groq-sdk";

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export const analyzeComplaint = async (complaintText) => {

  const prompt = `
You are an AI system for government complaint prioritization and fake complaint detection.

The complaint may be in English or Malayalam.

STEP 1 - FAKE COMPLAINT DETECTION:
First, determine if the complaint is fake, spam, or not a real civic issue.

A complaint is FAKE if it:
- Is gibberish, random characters, or keyboard mashing (e.g., "asdfgh", "qwerty")
- Is clearly not a civic/government issue (e.g., "I love pizza", "my cat is cute")
- Is a joke, prank, or test entry (e.g., "test", "hello world", "blah blah")
- Is abusive, offensive, or completely nonsensical
- Has no relation to any real public/civic problem
- Is just an emotion or personal opinion with no complaint (e.g., "I am sad", "life is hard")

A complaint is REAL if it:
- Describes a civic problem (roads, water, electricity, garbage, crime, health, etc.)
- Is written in Malayalam or English about a genuine public issue
- Even if poorly worded, clearly refers to a real government/municipal problem
- Mentions a specific location, infrastructure, or public service issue

STEP 2 - PRIORITY RULES (only if complaint is real):

HIGH:
English keywords: accident, injured, death, fire, emergency, hospital, ambulance, collapsed, flood, electrocution, gas leak, murder, assault, drowning, explosion, landslide, missing person, critical
Malayalam keywords: അപകടം, പരിക്ക്, മരണം, തീപിടിത്തം, അടിയന്തര, ആശുപത്രി, ആംബുലൻസ്, വെള്ളപ്പൊക്കം, മൃതദേഹം, കൊലപാതകം, മുങ്ങൽ, ഗ്യാസ് ചോർച്ച

MEDIUM:
English keywords: electricity issue, power cut, water problem, pipeline, road damage, pothole, traffic jam, drainage blocked, streetlight broken, sewage overflow, water leakage, transformer fault
Malayalam keywords: വൈദ്യുതി, വെള്ളം, റോഡ് കേടായി, ഗതാഗതക്കുരുക്ക്, കറന്റ് പോയി, ഡ്രെയിനേജ്, തെരുവ് ലൈറ്റ്, ട്രാൻസ്ഫോർമർ, ചോർച്ച, ഗർത്തം

LOW:
English keywords: garbage, cleanliness, noise, stray animals, bad smell, illegal parking, broken bench, park maintenance, dust, littering, mosquito breeding, overgrown trees, graffiti
Malayalam keywords: മാലിന്യം, ശുചിത്വം, ശബ്ദം, തെരുവ് നായ, ദുർഗന്ധം, കൊതുക്, മരം, ഗ്രാഫിറ്റി

STEP 3 - DEPARTMENT RULES (only if complaint is real):

Police:
English: crime, theft, robbery, violence, assault, harassment, murder, kidnapping, drug, illegal activity, suspicious person, vandalism, domestic abuse, chain snatching, eve teasing, stalking
Malayalam: കുറ്റകൃത്യം, മോഷണം, ആക്രമണം, പോലീസ്, കൊലപാതകം, തട്ടിക്കൊണ്ടുപോകൽ, ലഹരി, ശല്യം, മാനഭംഗം, ചങ്ങല പൊട്ടിക്കൽ

Health:
English: hospital, injury, ambulance, disease outbreak, dengue, cholera, food poisoning, dead animal, contaminated water, epidemic, malaria, health camp, vaccination, medical waste
Malayalam: ആശുപത്രി, പരിക്ക്, ആംബുലൻസ്, ഡെങ്കി, കോളറ, വിഷബാധ, മൃഗശവം, മഹാമാരി, മലേറിയ, വാക്സിൻ, വൈദ്യ മാലിന്യം

Electricity:
English: power cut, transformer, electric post, electric shock, short circuit, sparking wire, streetlight, power outage, meter issue, high voltage, low voltage, cable damage, illegal connection
Malayalam: വൈദ്യുതി, ട്രാൻസ്ഫോർമർ, ഇലക്ട്രിക് പോസ്റ്റ്, കറന്റ് ഷോക്ക്, തെരുവ് ലൈറ്റ്, ഷോർട്ട് സർക്യൂട്ട്, കറന്റ് പോയി, മീറ്റർ, ഉയർന്ന വോൾട്ടേജ്, കേബിൾ

Water:
English: water supply, pipeline, leakage, no water, water shortage, contaminated water, broken pipe, sewage mixing, water board, borewell, overhead tank, drainage overflow, flood water, dirty water
Malayalam: വെള്ളം, പൈപ്പ്, ചോർച്ച, വെള്ളക്കുറവ്, ജലവിതരണം, മലിനജലം, ഡ്രെയിനേജ്, ബോർവെൽ, ടാങ്ക്, വെള്ളപ്പൊക്കം, കുടിവെള്ളം

Transport:
English: road, pothole, traffic, accident, broken road, no signal, road blocked, speed breaker, road marking, footpath, bridge damage, road cave-in, diversion, highway issue, road widening, bus stop
Malayalam: റോഡ്, ഗതാഗതം, അപകടം, ഗർത്തം, ബ്രിഡ്ജ്, ട്രാഫിക്, ഫുട്പാത്ത്, ബസ് സ്റ്റോപ്പ്, ഡൈവേർഷൻ, റോഡ് തകർന്നു

Municipality:
English: garbage, waste collection, littering, open dumping, cleanliness, street cleaning, public toilet, mosquito fogging, drain cleaning, dead animal removal, illegal construction, encroachment, tree cutting, park, cemetery, stray dog
Malayalam: മാലിന്യം, ശുചിത്വം, മാലിന്യ ശേഖരണം, പൊതു ശൗചാലയം, കൊതുക്, ഡ്രെയിൻ, മൃഗശവം, അനധികൃത നിർമ്മാണം, മരം, ശ്മശാനം, തെരുവ് നായ

Complaint:
"${complaintText}"

Respond ONLY in this exact JSON format, nothing else:
{"isFake": false, "fakeReason": "", "priority": "high", "department": "Transport"}

If fake: {"isFake": true, "fakeReason": "Short user-friendly reason here", "priority": "low", "department": "Municipality"}
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
      temperature: 0,
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
      isFake: result.isFake === true,
      fakeReason: result.fakeReason || "",
      priority: result.priority?.toLowerCase() || "low",
      department: result.department || "Municipality",
      message: "✅ AI analyzed successfully"
    };

  } catch (err) {
    console.error("Groq error:", err.message);
    return fallbackAnalysis(complaintText, true);
  }
};


// 🔁 FALLBACK NLP (ALWAYS SAFE) - AI failure fallback, never blocks complaints
const fallbackAnalysis = (text, aiFailed = false) => {
  text = text.toLowerCase();

  let priority = "low";
  let department = "Municipality";

  if (
    text.includes("accident") || text.includes("injured") ||
    text.includes("emergency") || text.includes("death") ||
    text.includes("fire") || text.includes("flood") ||
    text.includes("electrocution") || text.includes("collapsed") ||
    text.includes("അപകടം") || text.includes("പരിക്ക്") ||
    text.includes("അടിയന്തര") || text.includes("വെള്ളപ്പൊക്കം") ||
    text.includes("മരണം") || text.includes("തീപിടിത്തം")
  ) {
    priority = "high";
    department = "Transport";
  }
  else if (
    text.includes("crime") || text.includes("theft") ||
    text.includes("robbery") || text.includes("violence") ||
    text.includes("assault") || text.includes("harassment") ||
    text.includes("murder") || text.includes("drug") ||
    text.includes("കുറ്റകൃത്യം") || text.includes("മോഷണം") ||
    text.includes("ആക്രമണം") || text.includes("കൊലപാതകം")
  ) {
    priority = "high";
    department = "Police";
  }
  else if (
    text.includes("hospital") || text.includes("injury") ||
    text.includes("ambulance") || text.includes("dengue") ||
    text.includes("disease") || text.includes("food poisoning") ||
    text.includes("ആശുപത്രി") || text.includes("ആംബുലൻസ്") ||
    text.includes("ഡെങ്കി") || text.includes("വിഷബാധ")
  ) {
    priority = "high";
    department = "Health";
  }
  else if (
    text.includes("electricity") || text.includes("power cut") ||
    text.includes("transformer") || text.includes("electric shock") ||
    text.includes("short circuit") || text.includes("streetlight") ||
    text.includes("വൈദ്യുതി") || text.includes("ട്രാൻസ്ഫോർമർ") ||
    text.includes("കറന്റ്") || text.includes("തെരുവ് ലൈറ്റ്")
  ) {
    priority = "medium";
    department = "Electricity";
  }
  else if (
    text.includes("water") || text.includes("pipeline") ||
    text.includes("leakage") || text.includes("water shortage") ||
    text.includes("sewage") || text.includes("contaminated water") ||
    text.includes("വെള്ളം") || text.includes("ജലവിതരണം") ||
    text.includes("പൈപ്പ്") || text.includes("ചോർച്ച") ||
    text.includes("വെള്ളക്കുറവ്") || text.includes("കുടിവെള്ളം")
  ) {
    priority = "medium";
    department = "Water";
  }
  else if (
    text.includes("road") || text.includes("pothole") ||
    text.includes("traffic") || text.includes("footpath") ||
    text.includes("bridge") || text.includes("bus stop") ||
    text.includes("റോഡ്") || text.includes("ഗതാഗതം") ||
    text.includes("ഗർത്തം") || text.includes("ബ്രിഡ്ജ്") ||
    text.includes("ട്രാഫിക്") || text.includes("ബസ് സ്റ്റോപ്പ്")
  ) {
    priority = "medium";
    department = "Transport";
  }

  console.log("✅ Using fallback:", { priority, department });

  return {
    isFake: false, // ✅ Fallback NEVER blocks complaints
    fakeReason: "",
    priority,
    department,
    message: aiFailed
      ? "⚠️ AI analysis failed, using fallback analysis"
      : "✅ Fallback analysis used"
  };
};