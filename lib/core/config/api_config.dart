class ApiConfig {
  // ⚠️ Toggle this to TRUE before building the APK for your client!
  static const bool isProduction = true;

  // Replace this with your hosted backend URL once you deploy (e.g., Render, Railway, Heroku)
  static const String productionUrl = 'https://buoy-erp-main.vercel.app/api';

  // Your local Wi-Fi IP for your own local development
  static const String localUrl = 'http://10.204.8.225:3000/api';

  static String get baseUrl => isProduction ? productionUrl : localUrl;
}
