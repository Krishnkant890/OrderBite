class PrintSettings {
  String storeId;
  String userId;
  String userName;
  String password;
  String apiUrl;

  PrintSettings({
    required this.storeId,
    required this.userId,
    required this.userName,
    required this.password,
    required this.apiUrl,
  });

  factory PrintSettings.empty() {
    return PrintSettings(
      storeId: '',
      userId: '',
      userName: '',
      password: '',
      apiUrl: 'https://www.highwycombebites.com', // Default production URL
    );
  }
}
