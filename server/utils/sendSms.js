import axios from "axios"

export const sendOtpSMS = async (mobile, otp) => {
  try {
    console.log('📱 Attempting to send SMS...')
    console.log('📱 To:', mobile)
    console.log('📱 OTP:', otp)
    
    if (!process.env.FAST2SMS_API_KEY) {
      throw new Error('FAST2SMS_API_KEY not found in environment variables')
    }

    // Remove any spaces or special characters from mobile number
    const cleanMobile = mobile.replace(/\D/g, '')
    
    // Ensure it's a 10-digit Indian number
    if (cleanMobile.length !== 10) {
      throw new Error('Invalid mobile number. Must be 10 digits.')
    }
    
    console.log('📱 Cleaned mobile:', cleanMobile)
    
    // Using v3 route (non-DLT, simple SMS)
    const response = await axios.get('https://www.fast2sms.com/dev/bulkV2', {
      params: {
        authorization: process.env.FAST2SMS_API_KEY,
        message: `Your Quick Griev OTP is ${otp}. Valid for 5 minutes. Do not share this code.`,
        route: 'v3',
        numbers: cleanMobile
      }
    })

    console.log('✅ SMS API Response:', JSON.stringify(response.data, null, 2))
    
    // Check if SMS was sent successfully
    if (response.data.return === false || response.data.status_code !== 200) {
      throw new Error(response.data.message || 'SMS sending failed')
    }
    
    console.log('✅ SMS sent successfully')
    return response.data
    
  } catch (error) {
    console.error('❌ Fast2SMS Error:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status
    })
    throw error
  }
}