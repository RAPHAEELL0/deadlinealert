# DeadlineAlert

A comprehensive deadline tracking application built with Flutter and Supabase backend. This app helps users manage their deadlines with categories, priorities, notifications, and intuitive task management features.

## Features

- **Task Management**
  - Create, edit, and delete deadlines with customizable details
  - Set priority levels (low, medium, high) with visual indicators
  - Organize tasks with user-defined categories
  - Mark tasks as complete with a simple checkbox
  - View deadlines by today, upcoming, and overdue status
  - Bulk reschedule overdue tasks to a future date

- **User Experience**
  - Clean, intuitive UI with smooth transitions
  - Light and dark theme support
  - Swipe actions for quick task actions
  - Detailed task views with all relevant information

- **Authentication**
  - Secure email and password authentication via Supabase
  - Protected routes requiring authentication
  - User-friendly error messages

- **Technical Features**
  - Real-time data synchronization with Supabase
  - Push notifications for upcoming deadlines
  - Environment variable configuration for security
  - Responsive design for various device sizes

## Project Structure

```
lib/
├── constants/       # App constants and configuration
├── models/          # Data models (Deadline, Category)
├── providers/       # State management with Riverpod
├── screens/         # UI screens
│   ├── auth/        # Authentication screens
│   ├── deadline/    # Deadline management screens
│   ├── category/    # Category management screens
├── services/        # Backend services
├── utils/           # Utility functions
├── widgets/         # Reusable UI components
└── main.dart        # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- A Supabase account and project

### Setting Up Supabase

1. Create a new project in [Supabase](https://supabase.com/)
2. Set up the following tables in your Supabase database:
   - `deadlines` - For storing user deadlines
   - `categories` - For storing user categories
3. Get your project URL and anon key from the API settings page

### Environment Setup

1. Clone the repository
   ```bash
   git clone https://github.com/RAPHAEELL0/deadlinealert.git
   cd deadlinealert
   ```

2. Create a `.env` file in the root directory with your Supabase credentials:
   ```
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   ```
   
   > ⚠️ **SECURITY WARNING**: Never commit your `.env` file to version control. This file contains sensitive API keys.

3. Install dependencies
   ```bash
   flutter pub get
   ```

### Running the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## Database Schema

### Deadlines Table
- `id` (UUID, PK)
- `title` (String)
- `description` (String)
- `due_date` (Timestamp)
- `is_completed` (Boolean)
- `priority` (String enum: 'low', 'medium', 'high')
- `category_id` (UUID, FK)
- `user_id` (UUID, FK)
- `device_id` (String)
- `created_at` (Timestamp)
- `updated_at` (Timestamp)

### Categories Table
- `id` (UUID, PK)
- `name` (String)
- `color` (String)
- `user_id` (UUID, FK)
- `device_id` (String)
- `created_at` (Timestamp)

## Security Considerations

- This app uses environment variables to securely store API keys
- Authentication is handled by Supabase's secure auth system
- Device IDs are used to store local data before authentication
- Data is migrated from device-based to user-based upon login

## Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[Add license information here]

## Acknowledgements

- [Flutter](https://flutter.dev/)
- [Riverpod](https://riverpod.dev/)
- [Supabase](https://supabase.com/)
- [GoRouter](https://pub.dev/packages/go_router)

## Priority Mode Feature

The DeadlineAlert app includes a priority mode feature that allows users to visually distinguish between deadlines based on their importance level. This feature enhances task organization and helps users quickly identify high-priority tasks.

### Features of Priority Mode

1. **Visual Priority Indicators**: Each deadline displays a color-coded indicator based on its priority level:
   - Green: Low priority
   - Orange: Medium priority
   - Red: High priority 

2. **Animated High Priority Tasks**: High-priority tasks feature a subtle pulsing animation to draw attention to urgent deadlines.

3. **Priority Filtering**: Users can filter their upcoming deadlines by priority level using the filter chips on the Upcoming screen.

4. **Enhanced Priority Selection**: When creating or editing a deadline, users can select from three priority levels with an intuitive visual interface.

5. **Consistent Visual Language**: Priority indicators maintain a consistent visual style throughout the app for better user experience.

### Implementation Details

The priority mode feature leverages the existing Priority enum (`low`, `medium`, `high`) in the Deadline model and enhances the UI with:

- A dedicated `PriorityBadge` widget for consistent representation
- Animation effects for high-priority items
- Color coding based on urgency level
- Enhanced form UI for selecting priority levels

This feature works with the existing database schema which already stores priority information for each deadline.
