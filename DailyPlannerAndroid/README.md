# Daily Planner Android App

A comprehensive daily planning application built with Jetpack Compose and Material 3 design.

## Features

### 📅 Date Selection
- Interactive calendar with month navigation
- Easy date selection to view different days
- Persistent data across different dates

### ✅ Tasks Management
- **Top 3 Priorities**: Focus on your most important tasks
- **Task List**: Add, complete, and delete tasks
- Checkbox completion with strikethrough effect
- Each task persists independently

### ⏰ Hourly Schedule
- 24-hour time slots (12 AM - 11 PM)
- Plan your day hour by hour
- Easy-to-use interface for scheduling

### 💪 Habit Tracker
- Track 7 daily habits:
  - 💧 Water
  - 🏃 Exercise
  - 🧘 Meditation
  - 📚 Reading
  - 😴 Sleep
  - 🥗 Nutrition
  - 💼 Work
- Visual progress indicator
- Simple tap to toggle completion

### 😊 Mood Tracker
- Track your daily mood:
  - 😄 Great
  - 🙂 Good
  - 😐 Okay
  - 😟 Bad
  - 😢 Terrible
- Visual mood selection interface

### 📝 Daily Notes
- Free-form text area for reflections
- Capture thoughts and notes for each day
- Persistent notes storage

## Technical Stack

- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM (Model-View-ViewModel)
- **Data Persistence**: DataStore Preferences
- **Serialization**: Gson
- **Minimum SDK**: 26 (Android 8.0)
- **Target SDK**: 34

## Project Structure

```
app/
├── src/
│   └── main/
│       ├── AndroidManifest.xml
│       └── java/com/rameshinampudi/dailyplanner/
│           ├── MainActivity.kt                 # Main entry point
│           ├── PlannerViewModel.kt            # ViewModel with business logic
│           ├── PlannerViewModelFactory.kt     # ViewModel factory
│           ├── data/
│           │   ├── PlannerData.kt            # Data models
│           │   └── PlannerRepository.kt      # Data persistence layer
│           └── ui/
│               ├── ContentView.kt            # Main UI composables
│               └── theme/
│                   ├── Theme.kt              # App theme
│                   └── Type.kt               # Typography
```

## Dependencies

```kotlin
// Core
- androidx.core:core-ktx:1.12.0
- androidx.lifecycle:lifecycle-runtime-ktx:2.7.0
- androidx.activity:activity-compose:1.8.2

// Compose
- androidx.compose:compose-bom:2023.10.01
- androidx.compose.material3:material3
- androidx.compose.material:material-icons-extended

// Architecture
- androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0
- kotlinx-coroutines-android:1.7.3

// Data
- androidx.datastore:datastore-preferences:1.0.0
- com.google.code.gson:gson:2.10.1
```

## Building the App

### Prerequisites
- Android Studio Hedgehog | 2023.1.1 or newer
- JDK 8 or higher
- Android SDK with API level 34

### Build Steps

1. **Open the project in Android Studio**
   ```bash
   cd DailyPlannerAndroid
   ```

2. **Sync Gradle files**
   - Android Studio should automatically prompt to sync
   - Or click: File → Sync Project with Gradle Files

3. **Run the app**
   - Connect an Android device or start an emulator
   - Click the Run button (▶) or press Shift+F10
   - Select your target device

### Build from Command Line

```bash
# Debug build
./gradlew assembleDebug

# Release build
./gradlew assembleRelease

# Install on connected device
./gradlew installDebug
```

## Usage

1. **Launch the app** to see today's planner
2. **Navigate between tabs** to access different features:
   - Tasks: Manage priorities and to-do items
   - Schedule: Plan your hourly activities
   - Habits: Track daily habits
   - Mood: Record how you're feeling
   - Notes: Write reflections
3. **Select different dates** using the calendar icon in the top bar
4. **All data is automatically saved** as you make changes

## Data Persistence

The app uses **DataStore Preferences** to persist all planner data:
- Data is stored locally on the device
- Survives app restarts
- Each date maintains independent data
- Automatic save on every change

## Future Enhancements

Potential features for future versions:
- Weekly/monthly view summaries
- Statistics and insights
- Reminder notifications
- Export data functionality
- Cloud sync
- Widget support
- Dark/Light theme toggle
- Custom habit creation

## License

This project is for personal use and learning purposes.

## Author

Ramesh Inampudi
