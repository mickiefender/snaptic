# Snaptic - NFC Ticketing System

A Flutter mobile application with Supabase backend for NFC wristband-based event ticketing system.

## Features

### 🎯 Core Features
- **Role-based Authentication**: Attendees and Organizers with different interfaces
- **NFC Integration**: Scan NFC wristbands for ticket validation
- **Event Management**: Create, manage, and promote events
- **Real-time Dashboard**: Live analytics and check-in monitoring
- **Ticket Management**: Purchase and validate tickets linked to NFC UIDs

### 👥 User Roles

#### Attendees
- Browse events feed (Instagram-style interface)
- Search and discover events
- Purchase tickets linked to NFC wristbands
- View personal tickets
- Stories and social features

#### Organizers
- Dashboard with analytics and metrics
- Create and manage events
- Scan NFC wristbands for ticket validation
- Monitor real-time check-ins
- Authorize ticket checkers
- View revenue and attendance data

## 🏗️ Tech Stack

- **Frontend**: Flutter (Cross-platform mobile)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Functions)
- **NFC**: Flutter NFC Manager package
- **Charts**: FL Chart for analytics
- **State Management**: Provider pattern
- **Image Handling**: Cached Network Image, Image Picker

## 🚀 Setup Instructions

### 1. Supabase Setup

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to SQL Editor in your Supabase dashboard
3. Run the SQL script from `supabase_setup.sql`
4. Go to Settings → API to get your URL and anon key
5. Create a storage bucket named 'event-images' in Storage section
6. Set up storage policies for image uploads

### 2. Flutter Configuration

1. Clone this repository
2. Open `lib/services/supabase_service.dart`
3. Replace the placeholders with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. Also update `lib/main.dart` with your credentials:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL_HERE',
     anonKey: 'YOUR_SUPABASE_ANON_KEY_HERE',
   );
   ```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Platform-specific Setup

#### Android
Add NFC permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature
    android:name="android.hardware.nfc"
    android:required="true" />
```

#### iOS
Add NFC capability to `ios/Runner/Info.plist`:

```xml
<key>com.apple.developer.nfc.readersession.formats</key>
<array>
    <string>NDEF</string>
    <string>TAG</string>
</array>
```

### 5. Run the Application

```bash
flutter run
```

## 📱 App Navigation

### Attendee Flow
1. **Authentication** → Login/Register with role selection
2. **Home Feed** → Instagram-style events feed with stories
3. **Search** → Discover events with grid layout
4. **Ticket Purchase** → Buy tickets linked to NFC wristbands
5. **Profile** → Manage account and view tickets

### Organizer Flow
1. **Authentication** → Login/Register as organizer
2. **Dashboard** → Analytics, metrics, and overview charts
3. **Event Management** → Create and manage events
4. **NFC Scanner** → Scan wristbands for ticket validation
5. **Checker Authorization** → Add staff members for scanning

## 🗄️ Database Schema

### Tables
- **profiles**: User information and roles
- **events**: Event details and metadata
- **tickets**: NFC UID to ticket mappings
- **checkers**: Authorized staff for ticket validation

### Key Relationships
- Events belong to Organizers (profiles)
- Tickets link Users to Events via NFC UID
- Checkers authorize staff for specific events

## 🔒 Security Features

- **Row Level Security (RLS)** enabled on all tables
- **Role-based access control** for different user types
- **JWT-based authentication** via Supabase Auth
- **Secure NFC UID validation** with database checks

## 📊 Analytics Features

- Total events created
- Ticket sales tracking
- Real-time check-in monitoring
- Revenue analytics with charts
- Attendance metrics

## 🎨 UI/UX Design

- **Material 3 Design System** with custom theming
- **Instagram-inspired** feed for attendees
- **Professional dashboard** for organizers
- **Responsive layouts** for different screen sizes
- **Smooth animations** and transitions
- **Accessibility-friendly** color contrast

## 🔧 Key Components

### Services
- `SupabaseService`: Database operations and auth
- `NfcService`: NFC tag reading functionality

### Providers
- `AuthProvider`: Authentication state management
- `EventsProvider`: Event data management

### Screens
- Authentication: Login/Register
- Attendee: Home Feed, Search, Profile
- Organizer: Dashboard, NFC Scanner, Event Creation

## 📝 Usage Examples

### Creating an Event (Organizer)
1. Navigate to Create tab
2. Fill event details and upload image
3. Set date, time, and pricing
4. Submit to create event

### Scanning NFC Tickets (Organizer)
1. Go to Scanner tab
2. Tap "Start NFC Scan"
3. Hold NFC wristband near device
4. View validation result

### Purchasing Tickets (Attendee)
1. Browse events in Home or Search
2. Tap on event card
3. Click "Buy Ticket"
4. Ticket automatically linked to NFC wristband

## 🚨 Important Notes

1. **NFC Hardware Required**: The app requires a device with NFC capability
2. **Supabase Credentials**: Must be configured before running
3. **Storage Setup**: Event images require Supabase storage bucket
4. **Testing**: Use NFC-enabled device or emulator with NFC simulation

## 📱 Screenshots

The app matches the provided UI designs:
- **Home Feed**: Instagram-style with stories and event cards
- **Search Screen**: Grid layout of event posters
- **Dashboard**: Analytics cards with charts and metrics

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
1. Check the Issues section
2. Review Supabase documentation
3. Flutter NFC Manager documentation
4. Create a new issue with detailed description

---

**Built with ❤️ using Flutter & Supabase**