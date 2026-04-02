# AtManagement: Decentralized P2P Project Management

AtManagement is a production-ready, multi-user project management application built using Flutter and the **atPlatform**. It delivers a true zero-trust, end-to-end encrypted collaboration experience where users can create projects, invite teammates, and assign tasks—all without relying on a centralized backend server or database.

---

## Architecture & How It Works

AtManagement completely bypasses traditional Client-Server architecture (like REST APIs + SQL/NoSQL databases). Instead, it relies on the **atPlatform's decentralized mesh network**. 

Every user on the platform has their own cryptographically secure cloud node called an **atServer**. When User A creates a task or project, it is saved securely to User A's local device and automatically synced to User A's atServer. When User A invites User B or assigns them a task, the payload is explicitly encrypted using a shared symmetric key, and sent peer-to-peer (P2P) straight to User B's atServer. 

### 1. The Core Provider State (`ProjectProvider`)
The entire application UI acts as a reactive listener to the `ProjectProvider`. When the app loads, the provider fetches the user's data from the local encrypted Hive keystore. The provider also initializes two silent **background listeners** via the `NotificationService` to listen for real-time `task_` and `project_` push events across the atPlatform.

### 2. Peer-to-Peer Encryption (`AtPlatformService`)
All CRUD (Create, Read, Update, Delete) operations are pushed through `at_platform_service.dart`. 
* **Self-Storage:** Data you own (like a project you created) is stored using a standard `AtKey` (e.g., `project_uid.atmanagement@youratsign`). 
* **Sharing:** To share a project, the service builds a shared key: `AtKey()..sharedWith = '@them'..sharedBy = '@you'..key = 'project_uid'`. When this key is `put()` into the network, the atPlatform automatically handles symmetric key generation, payload encryption, and delivery to the recipient's atServer.

### 3. Multi-Instance Isolation (Windows)
A major technical challenge in desktop development is testing real-time multi-user apps on a single machine. By default, `at_client` creates `.lock` files inside the system `temp` directory. If two Windows instances run simultaneously, they crash due to file-locking.
To solve this, `main.dart` intercepts the startup sequence and forcefully isolates the `hiveStoragePath`, `commitLogPath`, and `downloadPath` using a unique directory derived from the randomly-generated session or the specific AtSign. This allows two or more distinct executables to run simultaneously, perfectly simulating multiple users on a single machine!

---

## Tech Stack & Tools Used

### Frontend & Core
* **Flutter & Dart:** Chosen for writing a single codebase that natively compiles to beautiful desktop and mobile applications.
* **Provider:** Used for reactive state management (`ChangeNotifier`), ensuring that when the atPlatform background sync pushes new data, the UI updates synchronously and elegantly.
* **Flutter Slidable & Google Fonts:** Used to build a premium, highly tactile Kanban-style UI.

### Atsign Technologies
* **`at_client_mobile` / `at_client`:** The core SDK that handles local data persistence (using Hive), cryptographic hashing, key management, and syncing data between the local device and the remote atServer.
* **`at_onboarding_flutter`:** A drop-in UI library that completely handles the complex authentication flow (uploading `.atKeys` files, generating PKAM keypairs, and authenticating with the root server) so developers don't have to build auth from scratch.
* **`at_utils` (AtKey & NotificationService):** Used extensively for routing data. `NotificationService.subscribe()` is used to open an encrypted WebSocket connection directly to the atServer to catch instantaneous P2P invites.

---

## 🚀 Running the App Locally (Multi-User Windows Test)

Because this app explicitly supports isolated storage paths, you can test the real-time project collaboration by running **two applications simultaneously** on your Windows desktop. 

> [!WARNING]  
> Do **NOT** use `flutter run` in two separate terminals at the same time. MSBuild (Visual Studio) will attempt to lock the same build folder simultaneously, causing an `MSB3073` crash. Follow the steps below instead.

### Step 1: Install Dependencies
Clone the repository and fetch the Flutter packages:
```bash
flutter pub get
```

### Step 2: Launch User 1 (The Host)
Open your first terminal and run the app normally:
```bash
flutter run -d windows
```
Wait for the app to compile and launch. **Sign in** completely using your first `.atKeys` file (e.g., `@payablepasta59`).

### Step 3: Launch User 2 (The Teammate)
Leave Terminal 1 running. Open a **second, separate terminal** and bypass the build process by running the compiled executable directly from the build folder:
```powershell
.\build\windows\x64\runner\Debug\at_management.exe
```
This will pop open a second window right next to your first one. **Sign in** completely using your second `.atKeys` file (e.g., `@skyexperimental`).

### Step 4: Test Real-Time P2P Sharing!
1. In Window 1 (`@payablepasta59`), open the left `☰` Drawer and click **Team Members**.
2. Type in your second AtSign (`@skyexperimental`) and hit Invite.
3. You will instantly see a SnackBar popup cleanly appear in Window 2 confirming the invitation, and the Project Board will automatically sync and render!
4. Try creating a Task in Window 1 and assigning it to `@skyexperimental`. Watch it instantly appear in Window 2!
