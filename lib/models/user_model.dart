class UserModel {
  final String uid;
  final String email;
  final String? username;
  final String? photoUrl;
  final String? provider; // e.g., "email", "google", "apple"

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.photoUrl,
    this.provider,
  });

  // Convert UserModel to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'provider': provider,
    };
  }

  // Convert a Map (from Firestore) to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      email: map['email'],
      username: map['username'],
      photoUrl: map['photoUrl'],
      provider: map['provider'],
    );
  }
}
