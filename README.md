<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.13-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
  <img src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-success?style=for-the-badge" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>
</p>

<h1 align="center">🗡️ HUNTER SYSTEM</h1>
<h3 align="center">Solo Leveling Inspired RPG Progression Engine</h3>

<p align="center">
  <em>Transform your daily grind into an epic RPG journey. Level up your real life — one quest at a time.</em>
</p>

<p align="center">
  <a href="#-download"><strong>📥 Download APK</strong></a> •
  <a href="#-features"><strong>✨ Features</strong></a> •
  <a href="#-screenshots"><strong>📸 Screenshots</strong></a> •
  <a href="#-tech-stack"><strong>🛠️ Tech Stack</strong></a> •
  <a href="#-getting-started"><strong>🚀 Getting Started</strong></a>
</p>

---

## 🎮 About

**Hunter System** is a gamified self-improvement app inspired by the iconic anime/manhwa **Solo Leveling**. It turns your daily habits, workouts, coding challenges, study sessions, and discipline goals into RPG-style quests with XP rewards, stat growth, rank progression, and achievements.

You begin as an **E-Rank Hunter** and progressively level up through **D → C → B → A → S Rank** by completing real-life quests. The system tracks your physical and mental stats, maintains streak multipliers, throws surprise **Dungeon Break** challenges, and lets you compete on a live **Guild Leaderboard** — just like Sung Jin-Woo's journey from the weakest to the Shadow Monarch.

> *"I alone level up."* — Every Hunter who uses this app.

---

## 📥 Download

| Platform | Link |
|----------|------|
| 🤖 **Android APK** | [**Download Latest Release →**](https://github.com/kavya-dungrani/HUNTR/releases/latest) |
| 🌐 **Web** | https://hunter-system-sable.vercel.app/ |
| 🍎 **iOS** | Build from source (see [Getting Started](#-getting-started)) |

> **Minimum Requirements:** Android 5.0+ (API 21) • ~55MB

---

## ✨ Features

### ⚔️ Core RPG Engine
| Feature | Description |
|---------|-------------|
| **XP & Leveling** | Earn XP from quests with a scaling curve (`50 × (level-1)^1.5 × 1.5 + (level-1) × 75`). Max level: 999 |
| **6-Tier Rank System** | Progress through **E → D → C → B → A → S Rank** with unique color-coded badges |
| **5 Hunter Stats** | **STR** (Strength), **AGI** (Agility), **VIT** (Vitality), **INT** (Intelligence), **PERC** (Perception) |
| **HP & MP System** | Health and Mana bars that scale with your physical/mental XP and rank |
| **Combat Power Rating** | A calculated score from your level and all stat values |
| **Difficulty Grades** | E → D → C → B → A → S Class quests with scaling XP rewards (15 → 250 XP) |

### 📋 Quest System
| Feature | Description |
|---------|-------------|
| **Quest Codex Library** | 30+ pre-built quests across Physical, Coding, Study, Mental, Discipline, and Health categories |
| **Daily Protocols** | Auto-generated daily quests (4-5 diverse quests from different categories) |
| **Custom Quests** | Create your own quests with custom names, descriptions, difficulty, category, and stat targets |
| **Progress Tracking** | Incremental progress tracking with visual progress bars for every quest |
| **Category Filters** | Filter active quests by Physical, Coding, Study, Discipline, and more |

### 🔥 Streak & Bonus System
| Streak Duration | XP Bonus Multiplier |
|----------------|---------------------|
| 7+ days | +20% |
| 14+ days | +50% |
| 30+ days | +100% |
| 60+ days | +150% |
| 100+ days | +200% |

### 🏰 Dungeon Break Events
Time-limited emergency challenges that scale with your rank:

| Gate Level | Challenge Example | XP Reward |
|-----------|-------------------|-----------|
| **E-Rank** | 50 push-ups + 30 squats + 10-min jog | 500 XP |
| **D-Rank** | 3 LeetCode mediums + 1 hour study | 800 XP |
| **C-Rank** | 100 push-ups + 5 algorithm problems | 1,200 XP |
| **B-Rank** | 1-hour extreme physical + 2 hours code | 1,600 XP |
| **A-Rank** | 2-hour workout + 3 Hard problems + 2 hours study | 2,200 XP |
| **S-Rank** | 200 push-ups, 10km run, 5 Hard algos, 4 hours deep work | 3,500 XP |

> All Dungeon Break challenges have a **24-hour countdown timer** ⏰

### 🏆 Achievement & Title System
21 unlockable achievements across 6 categories:

- **Progression**: First Blood, Awakening, Proven Hunter, Veteran, Living Legend, Momentum, XP Sovereign
- **Consistency**: Relentless (30-day streak), Unstoppable (60-day), Iron Will (100-day)
- **Stat Mastery**: Titan Strength, Shadow Velocity, Immortal Vessel, Omniscient Mind, All-Seeing Eye
- **Code & Tech**: Code Architect (25 coding quests)
- **Rank Milestones**: D-Rank Awakening → S-Rank Shadow Monarch

Each achievement can unlock exclusive **Titles** like:
> *Shadow Monarch • National Level Hunter • Cyber Monarch • Iron Breaker • Phantom Step • Archmage*

### 🛡️ Hunter Identity System
| Feature | Description |
|---------|-------------|
| **Unique Hunter ID** | Auto-generated ID: `HUNTER-XXXXXX-AFFINITY` |
| **5 Affinities** | **STR** (Monarch of Destruction), **AGI** (Shadow Step Assassin), **VIT** (Immortal Vanguard), **INT** (Monarch of Shadows), **PERC** (Ruler's Authority) |
| **Equipped Titles** | Equip earned titles to display on your profile |
| **Status Window** | Full RPG character sheet with stats, XP, ranks, combat power, and badges |

### 🏅 Guild Leaderboard
- **Live Firestore-synced** global leaderboard ranked by Total XP
- Filter by rank tier (E through S)
- Displays Hunter ID, Level, Rank, Streak, Affinity, and Equipped Title
- Built-in demo data featuring iconic Solo Leveling characters (Sung Jin-Woo, Thomas Andre, Cha Hae-In, etc.)

### 🔐 Authentication
| Method | Status |
|--------|--------|
| Email/Password Sign Up & Login | ✅ |
| Google Sign-In | ✅ |
| Anonymous (Guest) Login | ✅ |
| Auto-login persistence | ✅ |

### 🧩 Additional Features
- **System Log & Notifications** — Tracks all quest completions, level-ups, and events
- **Level-Up Celebration Dialog** — Animated modal on every level-up with confetti
- **Rank-Up Notifications** — Special alerts when advancing to a new rank
- **Dark Mode UI** — Full Solo Leveling dark aesthetic with cyan/purple glow accents
- **Offline-First Architecture** — Works completely offline with SharedPreferences, syncs when online
- **System Settings** — Reset progress, sign out, and manage account
- **Quest Codex Browser** — Browse the full quest library with difficulty stars and add quests to your active list

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart 3.13) |
| **State Management** | Provider (ChangeNotifier) |
| **Authentication** | Firebase Auth (Email, Google, Anonymous) |
| **Database** | Cloud Firestore (real-time sync + offline) |
| **Local Storage** | SharedPreferences (offline-first cache) |
| **Typography** | Google Fonts (Rajdhani) |
| **Animations** | Confetti, custom pulse animations |
| **ID Generation** | UUID v4 |
| **Architecture** | MVVM-style (Models, Providers, Services, Screens, Widgets) |

---

## 🏗️ Project Architecture

```
lib/
├── main.dart                          # App entry point & root router
├── firebase_options.dart              # Firebase configuration (auto-generated)
│
├── models/
│   ├── game_engine.dart               # Core RPG engine (XP, levels, ranks, stats, quests)
│   ├── achievements.dart              # 21 achievements with unlock conditions
│   ├── daily_system.dart              # Daily quest generation & Dungeon Break events
│   └── quest_library.dart             # 30+ pre-built quest templates
│
├── providers/
│   └── hunter_provider.dart           # Central state manager (ChangeNotifier)
│
├── services/
│   ├── firebase_service.dart          # Auth, Firestore sync, local cache, leaderboard
│   └── audio_service.dart             # Sound effects service
│
├── screens/
│   ├── hunter_auth_screen.dart        # Login/signup with affinity selection
│   ├── hunter_hub_screen.dart         # Main dashboard (HUD, quests, dungeons)
│   ├── profile_screen.dart            # Status window (stats, achievements, combat power)
│   ├── leaderboard_screen.dart        # Guild leaderboard with rank filters
│   └── system_awakening_screen.dart   # First-time onboarding experience
│
├── widgets/
│   ├── add_quest_dialog.dart          # Custom quest creator
│   ├── level_up_dialog.dart           # Level-up celebration overlay
│   ├── notification_center_dialog.dart # System log viewer
│   ├── quest_codex_dialog.dart        # Quest library browser
│   └── system_settings_dialog.dart    # Settings & reset options
│
└── theme/
    └── hunter_theme.dart              # Complete design system (colors, gradients, styles)
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or later)
- [Dart SDK](https://dart.dev/get-dart) (3.13+)
- Android Studio / VS Code with Flutter extension
- A Firebase project (optional — app works offline without it)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/kavya-dungrani/HUNTR.git
cd HUNTR

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run

# 4. Build release APK
flutter build apk --release
```

### Firebase Setup (Optional)

The app works fully offline. To enable cloud sync and leaderboard:

1. Create a [Firebase project](https://console.firebase.google.com/)
2. Enable **Authentication** (Email/Password, Google, Anonymous)
3. Enable **Cloud Firestore**
4. Run `flutterfire configure` to generate `firebase_options.dart`
5. Place `google-services.json` in `android/app/`

---

## 🎨 Design Philosophy

The UI is built around the **Solo Leveling** aesthetic:

- **Dark dungeon background** (`#060912`) with subtle card surfaces
- **Cyan & Purple accent system** for primary actions and highlights
- **Red emergency gates** for Dungeon Break events
- **Color-coded rank badges**: Slate (E) → Green (D) → Blue (C) → Purple (B) → Gold (A) → Pink (S)
- **Rajdhani typography** for that futuristic RPG feel
- **Glow effects** on interactive elements with dynamic shadows
- **Military-style naming** for UI sections (HUD, Protocols, Status Window, Codex)

---

## 📱 Quest Categories

| Category | Stat Affected | Example Quests |
|----------|--------------|----------------|
| 🏋️ Physical | STR, VIT | Push-ups, Squats, Planks, Pull-ups |
| 🏃 Fitness | AGI | Morning Jog, 5km Run, 10km Marathon |
| 💻 Coding | INT | LeetCode Problems, Git Commits, Deep Code |
| 📖 Study | INT | Read 20 Pages, Focused Study, Monk Mode |
| 🧠 Mental | PERC | Meditation, Journaling |
| 💪 Discipline | VIT, PERC | Cold Shower, Digital Detox, Clean Eating |
| ❤️ Health | VIT | Hydration, Sleep |
| 🎨 Creative | — | Custom quests |
| 💰 Financial | — | Custom quests |
| 🤝 Social | — | Custom quests |

---

## 🧪 Sample Quest Library

| Quest | Difficulty | XP | Target |
|-------|-----------|-----|--------|
| 20 Push-ups | E-Class ★☆☆☆☆☆ | 15 | 20 reps |
| 50 Push-ups | C-Class ★★★☆☆☆ | 60 | 50 reps |
| Century Push-up Challenge | B-Class ★★★★☆☆ | 100 | 100 reps |
| Iron Discipline: 200 Push-ups | A-Class ★★★★★☆ | 150 | 200 reps |
| 10km Marathon Hunter Trial | S-Class ★★★★★★ | 250 | 10 km |
| Solve 1 LeetCode Problem | E-Class ★☆☆☆☆☆ | 15 | 1 problem |
| LeetCode Hard Trial | A-Class ★★★★★☆ | 150 | 1 problem |
| Monk Mode Study: 3 Hours | A-Class ★★★★★☆ | 150 | 180 min |
| Cold Shower Awakening | D-Class ★★☆☆☆☆ | 35 | 3 min |
| Digital Detox: No Social Media 24h | B-Class ★★★★☆☆ | 100 | 24 hours |

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Solo Leveling** (나 혼자만 레벨업) by Chugong — for the inspiration
- Flutter & Firebase teams — for the incredible framework and backend
- The self-improvement community — for proving that life is the ultimate RPG

---

<p align="center">
  <strong>⚔️ ARISE, HUNTER. YOUR SYSTEM AWAITS. ⚔️</strong>
</p>
<p align="center">
  <em>Built with 💜 by <a href="https://github.com/kavya-dungrani">Kavya Dungrani</a></em>
</p>
