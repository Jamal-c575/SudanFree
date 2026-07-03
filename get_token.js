const { GoogleAuth } = require('google-auth-library');
const auth = new GoogleAuth({
  keyFile: '/home/jamal/Projects/SUDAN-App/المتجر/sudanfree-d04fc-firebase-adminsdk-fbsvc-ef0fdc49d3.json',
  scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']
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
