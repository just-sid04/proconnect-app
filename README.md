# ProConnect - Smart Local Service Provider Platform

A comprehensive cross-platform application that connects people who need services with nearby skilled workers such as electricians, plumbers, appliance repair technicians, computer technicians, tutors, and other local service providers.

## Features

### For Customers
- Browse and search for service providers by category
- View provider profiles, ratings, and reviews
- Book services with date, time, and location
- Track booking status in real-time
- Rate and review completed services
- Find nearby providers based on location

### For Service Providers
- Create and manage service provider profile
- Add skills, experience, and availability
- Receive and manage booking requests
- Accept, start, and complete bookings
- View earnings and statistics
- Build reputation through ratings and reviews

### For Admin
- Dashboard with platform statistics
- Manage users (customers and providers)
- Verify provider applications
- Manage service categories
- Monitor bookings and transactions
- Handle reviews and reports

## Tech Stack

### Backend
- **Node.js** with **Express.js**
- **JSON file storage** for simplicity
- **JWT** authentication
- **bcryptjs** for password hashing
- RESTful API architecture

### Frontend (Cross-Platform)
- **Flutter** with **Dart**
- Works on Android, iOS, Web, and Desktop
- Material Design principles
- Provider pattern for state management

### Admin Dashboard
- **HTML**, **CSS**, **JavaScript**
- Responsive design
- Modern UI with Poppins font

## Project Structure

```
proconnect/
├── backend/                 # Node.js + Express Backend
│   ├── data/               # JSON database files
│   │   ├── users.json
│   │   ├── providers.json
│   │   ├── bookings.json
│   │   ├── reviews.json
│   │   └── categories.json
│   ├── middleware/         # Auth, validation, upload
│   ├── routes/            # API routes
│   ├── utils/             # Database utilities
│   ├── server.js          # Main server file
│   └── package.json
│
├── frontend/               # Flutter Application
│   ├── lib/
│   │   ├── models/        # Data models
│   │   ├── providers/     # State management
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API services
│   │   ├── widgets/       # Reusable widgets
│   │   └── main.dart
│   └── pubspec.yaml
│
├── admin-dashboard/        # HTML Admin Panel
│   ├── css/
│   ├── js/
│   └── index.html
│
└── README.md
```

## Installation & Setup

### Prerequisites
- Node.js (v16 or higher)
- Flutter SDK (v3.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

4. Edit `.env` file with your configuration:
```
PORT=3000
NODE_ENV=development
JWT_SECRET=your-super-secret-key
ADMIN_EMAIL=admin@proconnect.com
ADMIN_PASSWORD=admin123
```

5. Start the server:
```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

The backend API will be available at `http://localhost:3000`

### Flutter Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Get Flutter dependencies:
```bash
flutter pub get
```

3. Update API base URL in `lib/utils/constants.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

4. Run the app:
```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS (macOS only)
flutter run -d ios

# For desktop (Windows/Linux/macOS)
flutter run -d windows
flutter run -d linux
flutter run -d macos
```

### Admin Dashboard Setup

The admin dashboard is a static HTML/CSS/JS application. Simply open `admin-dashboard/index.html` in a web browser or serve it using any static file server.

```bash
# Using Python
python -m http.server 8080

# Using Node.js npx
npx serve .

# Using PHP
php -S localhost:8080
```

Then access the dashboard at `http://localhost:8080/admin-dashboard/`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user
- `POST /api/auth/logout` - Logout user

### Users
- `GET /api/users` - Get all users (admin)
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Providers
- `GET /api/providers` - Get all providers
- `GET /api/providers/nearby` - Get nearby providers
- `GET /api/providers/:id` - Get provider by ID
- `POST /api/providers` - Create provider profile
- `PUT /api/providers/:id` - Update provider
- `PUT /api/providers/:id/availability` - Update availability

### Bookings
- `GET /api/bookings` - Get bookings
- `GET /api/bookings/:id` - Get booking by ID
- `POST /api/bookings` - Create booking
- `PUT /api/bookings/:id` - Update booking
- `PUT /api/bookings/:id/status` - Update booking status
- `DELETE /api/bookings/:id` - Delete booking

### Reviews
- `GET /api/reviews` - Get reviews
- `POST /api/reviews` - Create review
- `PUT /api/reviews/:id` - Update review
- `DELETE /api/reviews/:id` - Delete review

### Categories
- `GET /api/categories` - Get all categories
- `GET /api/categories/:id` - Get category by ID
- `POST /api/categories` - Create category (admin)
- `PUT /api/categories/:id` - Update category (admin)
- `DELETE /api/categories/:id` - Delete category (admin)

### Admin
- `GET /api/admin/dashboard` - Get dashboard stats
- `GET /api/admin/users` - Get all users
- `GET /api/admin/verifications/pending` - Get pending verifications
- `PUT /api/admin/providers/:id/verify` - Verify provider

## Default Credentials

### Admin
- Email: `admin@proconnect.com`
- Password: `admin123`

### Test Users (from seed data)
- Customer: `customer@example.com` / any password
- Provider: `provider@example.com` / any password

## User Flows

### Customer Flow
1. Register/Login as Customer
2. Browse service categories
3. View provider profiles and reviews
4. Book a service with details
5. Track booking status
6. Rate and review after completion

### Provider Flow
1. Register/Login as Provider
2. Create provider profile with skills and availability
3. Wait for admin verification
4. Receive booking requests
5. Accept and complete bookings
6. Build reputation through reviews

### Admin Flow
1. Login as Admin
2. View dashboard statistics
3. Verify new provider applications
4. Manage users and bookings
5. Monitor platform activity

## Screenshots

*Screenshots will be added here*

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License.

## Support

For support, email support@proconnect.com or join our Slack channel.

---

Built with ❤️ by the ProConnect Team
