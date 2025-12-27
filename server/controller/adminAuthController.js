export const adminLogin = async (req, res) => {
  try {
    const { department, username, password } = req.body;

    // 1️⃣ Validate input
    if (!department || !username || !password) {
      return res.status(400).json({
        success: false,
        message: "All fields are required",
      });
    }

    // 2️⃣ Build env keys
    const key = department.toUpperCase();
    const envUsername = process.env[`${key}_USERNAME`];
    const envPassword = process.env[`${key}_PASSWORD`];

    // 3️⃣ Check department exists
    if (!envUsername || !envPassword) {
      return res.status(401).json({
        success: false,
        message: "Invalid department",
      });
    }

    // 4️⃣ 🔥 ACTUAL AUTH CHECK (THIS WAS MISSING)
    if (username !== envUsername || password !== envPassword) {
      return res.status(401).json({
        success: false,
        message: "Invalid username or password",
      });
    }

    // 5️⃣ Success
    return res.json({
      success: true,
      message: "Login successful",
      admin: {
        department,
      },
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
