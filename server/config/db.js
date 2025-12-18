import mongoose from "mongoose";
const connectDB=async()=>{
    try{
        mongoose.connection.on('connected',()=>{
            console.log("mongodb connected successfully")
        })
        await mongoose.connect(`${process.env.MONGODB_URI}`)

    }
    catch(error)
    {
        console.log("connection failed",error)

    }
}
export default connectDB