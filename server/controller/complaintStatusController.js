import Complaint from "../model/complaint.js";
import Status from "../model/status.js";

export const adminComplaintStatus=async(req,res)=>{
    try
    {
        const {complaintId}=req.params
        const{message,status,department}=req.body
        if(!message || !department)
        {
             return res.status(400).json({
            success: false,
            message: "Message and department are required",
      });
        }
        const complaint=await Complaint.findById(complaintId)
          if (!complaint) {
      return res.status(404).json({
        success: false,
        message: "Complaint not found",
      });
    }
        const update=await Status.create({
            complaintId:complaint._id,
            userId:complaint.userId,
            department,
            message,
            status: status || complaint.status,
        })
        complaint.status=status||complaint.status
        await complaint.save()
          res.status(201).json({
      success: true,
      message: "Complaint status updated",
      update,
    })

    }
    catch(error)
    {
         console.error("Status update error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
    });

    }
}