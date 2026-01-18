# 🎬 Moviq – Social Movie App

Moviq is a social movie application where users can discover movies, manage watchlists, write reviews, and interact with friends.  
The app combines movie discovery (similar to IMDb) with social and community features.

This project was developed as a **group project** during the first semester of the HBO-ICT program.

---

## 📱 Features

- User authentication (Google login & email/password)
- Movie discovery (popular & upcoming movies)
- Movie details page:
  - Poster, title, genre, overview
  - Trailer & where to watch
  - Cast & similar movies
- Actor profiles (biography & filmography)
- Reviews & ratings (add, edit, delete)
- Watchlist & watched list
- Custom user-created lists
- Share lists with friends
- Chat with friends:
  - Text messages
  - Image messages
  - Voice messages
  - Reactions, reply, edit & delete
- User profile & settings
- Favorites & top 3 favorite movies
- Movie recommendations based on user activity
- Chatbot for movie-related questions and suggestions
---

## 🛠 Technologies Used

### Frontend
- Flutter
- Dart
- Material UI

### Backend / Cloud
- Firebase Authentication
- Cloud Firestore
- Firebase Storage

### APIs
- TMDB API (movies & actors data)

### Development Tools
- Android Studio
- Xcode (iOS)
- VS Code
- GitHub
- Figma

---
To use the chatbot, **Ollama must be installed and running locally**.

#### Ollama Setup
1. Download Ollama from: https://ollama.com  
2. Install Ollama on your computer  
3. Start Ollama and make sure it is running in the background  
   ```bash
   ollama run llama3
---
## 📂 Project Structure

```

lib/
├── auth/           # Authentication logic
├── models/         # Data models (movie, user, review, chat)
├── services/       # Firebase & API services
├── screens/        # App screens (dashboard, details, chat, profile)
├── widgets/        # Reusable UI components
└── main.dart       # App entry point

````

---

## 🚀 Installation & Setup

### 1. Prerequisites

Make sure the following are installed:

- Flutter SDK
- Dart SDK
- Android Studio (with Android Emulator)
- Xcode (macOS only, for iOS)
- CocoaPods

Check installation:
```bash
flutter doctor
````

---

### 2. Clone the Repository

```bash
git clone https://github.com/your-repo/moviq.git
cd moviq
```

---

### 3. Install Dependencies

```bash
flutter pub get
```

---

## 🔥 Firebase Setup

### 1. Create Firebase Project

1. Go to [https://firebase.google.com](https://firebase.google.com)
2. Create a new project
3. Add Android and iOS apps
4. Download:

   * `google-services.json` (Android)
   * `GoogleService-Info.plist` (iOS)

Place them in the correct folders.

---

### 2. Enable Firebase Services

Enable:

* Firebase Authentication

  * Google Sign-In
  * Email/Password
* Cloud Firestore
* Firebase Storage

---

### 3. Firestore Security Rules 

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    /* ================= HELPERS ================= */
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isFriend(userId) {
      return isSignedIn()
        && exists(/databases/$(database)/documents/users/$(userId)/friends/$(request.auth.uid));
    }

    /* ================= USERS ================= */
    match /users/{userId} {

      // Owner: full access
      allow read, write, list: if isOwner(userId);

      // Friends: read-only profile
      allow read: if isFriend(userId);
        allow read: if request.auth != null;

      match /preferences/{docId} {
        allow read, write: if isOwner(userId);
      }

      // favorites, watchlist, reviews, chatbot signals
      match /interactions/{interactionId} {
        allow read, write: if isOwner(userId);
      }

      /* ===== WATCHED ===== */
      match /watched/{movieId} {
        allow read, write: if isOwner(userId);
      }

      /* ===== LISTS ===== */
      match /lists/{listId} {
        allow read, write: if isOwner(userId);

        match /items/{itemId} {
          allow read, write: if isOwner(userId);
        }
      }

      /* ===== RECENTLY VIEWED ===== */
      match /recently_viewed/{movieId} {
        allow read: if isOwner(userId) || isFriend(userId);
        allow write: if isOwner(userId);
      }

      /* ===== WATCHLIST ===== */
      match /watchlist/{movieId} {
        allow read, write: if isOwner(userId);
      }

      /* ===== PROFILE FAVORITES ===== */
      match /profile_faves/{slotId} {
        allow read, write: if isOwner(userId);
      }

      /* ===== FAVORITES ===== */
      match /favorites/{movieId} {
        allow read, write: if isOwner(userId);
      }

      /* ===== FRIENDS ===== */
      match /friends/{friendId} {
        allow read: if isOwner(userId)
          || (isSignedIn() && request.auth.uid == friendId);

        allow write: if isOwner(userId)
          || (isSignedIn() && request.auth.uid == friendId);
      }

      /* ===== FRIEND REQUESTS ===== */
      match /friend_requests/{requestId} {
        allow read, update, delete: if isOwner(userId);
        allow create: if isSignedIn();
      }

      /* ===== SENT REQUESTS ===== */
      match /sent_requests/{requestId} {
        allow read, write: if isOwner(userId);
        allow delete: if isSignedIn() && request.auth.uid == requestId;
      }
    }

    /* ================= USERNAME INDEX ================= */
    match /usernames/{username} {
      allow read: if isSignedIn();

      allow write: if isSignedIn()
        && (
          request.resource.data.uid == request.auth.uid
          || resource.data.uid == request.auth.uid
        );
    }

    /* ================= MOVIES ================= */
    match /movies/{movieId} {

      match /reviews/{reviewId} {
        allow read: if true;
        allow write: if isSignedIn() && request.auth.uid == reviewId;
      }

      match /meta/{docId} {
        allow read: if true;
        allow write: if isSignedIn();
      }
    }

    /* ===== COLLECTION GROUP REVIEWS ===== */
    match /{path=**}/reviews/{reviewId} {
      allow read: if true;
    }

    /* ================= SEARCH HISTORY ================= */
    match /search_history/{userId}/terms/{termId} {
      allow read, write: if isOwner(userId);
    }

 match /chats/{chatId} {
  allow read, list: if request.auth != null
    && request.auth.uid in resource.data.participants;

  allow create: if request.auth != null
    && request.auth.uid in request.resource.data.participants;

  allow update: if request.auth != null
    && request.auth.uid in resource.data.participants;

  match /messages/{messageId} {
    allow read, create: if request.auth != null
      && request.auth.uid in
         get(/databases/$(database)/documents/chats/$(chatId))
           .data.participants;

    // Allow participants to update (needed for seenBy, hearts, deletes, etc.)
    allow update: if request.auth != null
      && request.auth.uid in
         get(/databases/$(database)/documents/chats/$(chatId))
           .data.participants;

    // Optional: allow sender to delete their own message
    allow delete: if request.auth != null
      && request.auth.uid == resource.data.senderId;
  }
}
match /ai_chats/{chatId} {

  allow read, create: if request.auth != null
    && request.resource.data.userId == request.auth.uid;

  allow read: if request.auth != null
    && resource.data.userId == request.auth.uid;

  match /messages/{messageId} {
    allow read, create: if request.auth != null
      && request.auth.uid ==
         get(/databases/$(database)/documents/ai_chats/$(chatId))
           .data.userId;

    allow update, delete: if false;
  }
}

  }
}

```

---

### 4. Firebase Storage Rules 

```js
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_photos/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    match /chat_images/{chatId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }

    match /voice_messages/{chatId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }

    match /profile_photos/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## 🎥 TMDB API Setup

1. Create an account at [https://www.themoviedb.org](https://www.themoviedb.org)
2. Generate an API key
3. Add the API key to your project

⚠️ Do **not** commit API keys to GitHub.

---

## ▶️ Run the App

```bash
flutter run
```

Select:

* Android Emulator
* iOS Simulator
* Physical device

---

## 👥 Team

Moviq is a group project created by HBO-ICT students as the final project of the start semester.

**Team members:**
- Enas Hazbar
- Daniela Hodaka
- Abdirahman Hassan
- Süeda İlhan


---

## 🎯 Project Goal

The goal of Moviq is to:

* Combine movie discovery with social interaction
* Practice mobile app development using Flutter
* Learn Firebase authentication, database design, and real-time systems
* Work collaboratively in a team environment

---

## 📸 Screenshots

### Core App Screens

| Login | Dashboard | Movie Details |
|------|-----------|---------------|
| <img src="https://github.com/user-attachments/assets/a0d1993c-1e2b-4a98-9b29-a316333dba94" width="250" /> | <img src="https://github.com/user-attachments/assets/aa2d908e-7cbb-482e-9054-9c0a760a005f" width="250" /> | <img src="https://github.com/user-attachments/assets/6b04aaa1-b477-40eb-a80c-0c1a2482cefb" width="250" />
| Reviews | Lists | Search |
|---------|-------|--------|
| <img src="https://github.com/user-attachments/assets/6b04aaa1-b477-40eb-a80c-0c1a2482cefb" width="250" /> | <img src="https://github.com/user-attachments/assets/0334b048-e9bf-4d3c-ae3e-e76261c6637c" width="250" /> | <img src="https://github.com/user-attachments/assets/d5d4f7eb-51b5-4bd1-8dcf-8ae3207b25d3" width="250" /> |

---

### Social & Profile Features

| Chatbot | Chats | Favourites |
|---------|-------|------------|
| <img src="https://github.com/user-attachments/assets/2d2e6087-e54f-49a9-a249-2c36e37677e9" width="250" /> | <img src="https://github.com/user-attachments/assets/7268d324-29f2-48ca-98e3-23d0fe6a6eb6" width="250" /> | <img src="https://github.com/user-attachments/assets/bcfc4e3e-e6db-4301-9f58-ddfe0d95a622" width="250" /> |

| Profile | Friends List | Settings |
|---------|--------------|----------|
| <img src="https://github.com/user-attachments/assets/c0839b51-e2be-49e6-96d5-5b9978822ef3" width="250" /> | <img src="https://github.com/user-attachments/assets/5054569b-247f-4050-91ab-ba8425f680f9" width="250" /> | <img src="https://github.com/user-attachments/assets/f7e7a90f-38f7-443a-ba6d-1ab8f63bede7" width="250" /> |


---

## 📄 License

This project was created for educational purposes.
