const { GoogleAuth } = require('google-auth-library');
const auth = new GoogleAuth({
  keyFile: '/home/jamal/Projects/SUDAN-App/key.json',
  scopes: [
    "email",
    "openid",
    "https://www.googleapis.com/auth/cloudplatformprojects.readonly",
    "https://www.googleapis.com/auth/firebase",
    "https://www.googleapis.com/auth/cloud-platform"
  ]
});
async function getAccessToken() {
  try {
      const client = await auth.getClient();
      const token = await client.getAccessToken();
      console.log(token.token);
  } catch (e) {
      console.error(e);
  }
}
getAccessToken();
