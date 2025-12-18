import { Clerk } from '@clerk/clerk-sdk-node'

const clerk = new Clerk({ 
  secretKey: process.env.CLERK_SECRET_KEY 
})

export class ClerkSmsService {
  
  // Send OTP to mobile number
  static async sendMobileOtp(phoneNumber) {
    try {
      console.log('📱 Sending SMS OTP via Clerk...')
      console.log('📱 To:', phoneNumber)
      
      // Format phone number (add +91 if not present)
      let formattedPhone = phoneNumber.replace(/\D/g, '') // Remove non-digits
      
      if (formattedPhone.length === 10) {
        formattedPhone = '+91' + formattedPhone // Add India country code
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+' + formattedPhone
      }
      
      console.log('📱 Formatted:', formattedPhone)

      // Create a phone number verification attempt
      const phoneNumberAttempt = await clerk.phoneNumbers.createPhoneNumber({
        phoneNumber: formattedPhone,
      })

      // Start verification (sends OTP)
      await clerk.phoneNumbers.createPhoneNumberVerification({
        phoneNumberId: phoneNumberAttempt.id,
        strategy: 'phone_code' // Send verification code via SMS
      })

      console.log('✅ SMS OTP sent via Clerk')
      
      return {
        success: true,
        phoneNumberId: phoneNumberAttempt.id,
        formattedPhone
      }
      
    } catch (error) {
      console.error('❌ Clerk SMS Error:', error.errors || error.message)
      throw new Error(error.errors?.[0]?.message || 'Failed to send SMS OTP')
    }
  }

  // Verify mobile OTP
  static async verifyMobileOtp(phoneNumberId, code) {
    try {
      console.log('📱 Verifying SMS OTP with Clerk...')
      
      const verification = await clerk.phoneNumbers.verifyPhoneNumber({
        phoneNumberId,
        code
      })

      const isVerified = verification.verification.status === 'verified'
      
      console.log(isVerified ? '✅ SMS OTP verified' : '❌ Invalid SMS OTP')
      
      return {
        success: isVerified,
        phoneNumber: verification.phoneNumber
      }
      
    } catch (error) {
      console.error('❌ SMS Verification Error:', error.errors || error.message)
      return {
        success: false,
        error: error.errors?.[0]?.message || 'Invalid OTP'
      }
    }
  }
}