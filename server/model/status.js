import mongoose from "mongoose";

const complaintStatusSchema = new mongoose.Schema(
  {
    complaintId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "complaint", // ✅ matches Complaint model name
      required: true,
    },

    // ✅ MATCHES Complaint.userId (String)
    userId: {
      type: String,
      required: true,
    },

    department: {
      type: String,
      enum: [
        "Police",
        "Health",
        "Electricity",
        "Water",
        "Municipality",
        "Transport",
      ],
      required: true,
    },

    message: {
      type: String,
      required: true,
    },

    // ✅ EXACTLY SAME AS Complaint.status
    status: {
      type: String,
      enum: ["Received", "In Progress", "Resolved"],
      default: "Received",
    },

    sentBy: {
      type: String,
      enum: ["ADMIN", "SYSTEM"],
      default: "ADMIN",
    },
  },
  { timestamps: true }
);

const Status = mongoose.model("status", complaintStatusSchema);
export default Status;
