import axios from "axios";

export const sendOtpSMS = async (mobile, otp) => {
  const options = {
    method: "POST",
    url: "https://www.fast2sms.com/dev/bulkV2",
    headers: {
      authorization: process.env.FAST2SMS_API_KEY,
      "Content-Type": "application/json"
    },
    data: {
      route: "otp",
      variables_values: otp,
      numbers: mobile
    }
  };

  await axios.request(options);
};
