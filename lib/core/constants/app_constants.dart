class AppConstants {
  // App general
  static const String appName = 'WanderBite';
  static const int splashDuration = 2; // in seconds

  // Routes
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String homeRoute = '/home';
  static const String mapsRoute = '/maps';
  static const String calendarRoute = '/calendar';
  static const String multimediaRoute = '/multimedia';
  static const String audioRoute = '/multimedia/audio';
  static const String photoRoute = '/multimedia/photo';
  static const String videoRoute = '/multimedia/video';
  static const String profileRoute = '/profile';
  static const String userDataViewRoute = '/profile/userdata';
  static const String notificationsRoute = '/notifications';

  // Theme types
  static const String travelTheme = 'travel';
  static const String recipeTheme = 'recipe';

  // SharedPreferences keys
  static const String themeKey = 'selected_theme';
  static const String isLoggedInKey = 'is_logged_in';
  static const String userNameKey = 'user_name';

  // Map default settings
  static const double defaultLatitude = 37.422160;
  static const double defaultLongitude = -122.084270;
  static const double defaultZoom = 14.0;
}
