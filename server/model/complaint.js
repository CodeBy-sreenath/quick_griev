import mongoose from 'mongoose'
const complaintSchema=new mongoose.Schema({
    userId:{type:String},
    complaintText:{type:String,required:true},
    language:{type:String,enum:["en","ml"],required:true},
    imageUrl:{type:String},
    voiceText:{type:String},
    priority:{type:String,enum:["high","medium","low"],default:"low"},
    status:{type:String,enum:["Received","Inprogress","Resolved"],
        default:"Received"
    },
    location:{type:String},




},{timestamps:true})
const Complaint=mongoose.model("complaint",complaintSchema)
export default Complaint