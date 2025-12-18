import sgMail from "@sendgrid/mail"

sgMail.setApiKey(process.env.SENDGRID_API_KEY)

export const sendOtpEmail = async (email, otp) => {
  try {
    console.log('📧 Attempting to send email...')
    console.log('📧 To:', email)
    console.log('📧 From:', process.env.SENDGRID_FROM_EMAIL)
    
    // Validation
    if (!process.env.SENDGRID_API_KEY) {
      throw new Error('SENDGRID_API_KEY not found in environment variables')
    }
    
    if (!process.env.SENDGRID_FROM_EMAIL) {
      throw new Error('SENDGRID_FROM_EMAIL not found in environment variables')
    }

    const msg = {
      to: email,
      from: process.env.SENDGRID_FROM_EMAIL,
      subject: "Your OTP Code - Quick Griev",
      text: `Your OTP is: ${otp}. This code expires in 5 minutes.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; max-width: 600px;">
          <h2 style="color: #333;">Your OTP Code</h2>
          <p style="color: #666;">Your verification code is:</p>
          <div style="background: #f5f5f5; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <h1 style="color: #4CAF50; font-size: 36px; letter-spacing: 8px; margin: 0;">${otp}</h1>
          </div>
          <p style="color: #666;">This code will expire in <strong>5 minutes</strong>.</p>
          <p style="color: #999; font-size: 12px;">If you didn't request this code, please ignore this email.</p>
        </div>
      `
    }

    const response = await sgMail.send(msg)
    console.log('✅ Email sent successfully')
    return response
  } catch (error) {
    console.error('❌ SendGrid Error Details:', {
      message: error.message,
      code: error.code,
      response: error.response?.body
    })
    throw error
  }
}