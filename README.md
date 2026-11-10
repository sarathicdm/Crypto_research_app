# Crypto Research App

A Flutter-based cryptocurrency research application that helps users explore cryptocurrency market data, view individual coin information, track historical price movements, and monitor overall market statistics.

The application uses a **Flutter frontend** and a **Python FastAPI backend** integrated with the CoinGecko API.

## Features

- **Cryptocurrency Market List:** View available cryptocurrencies with their prices and market information.
- **Coin Details:** View detailed information about individual cryptocurrencies.
- **Historical Price Charts:** Explore historical price movements through interactive charts.
- **Search:** Search for cryptocurrencies by name or coin ID.
- **Sorting & Filtering:** Organize cryptocurrency market data.
- **Watchlist:** Save and track favourite cryptocurrencies.
- **Market Statistics:** View overall cryptocurrency market information.
- **API Integration:** Fetch real-time cryptocurrency market data using the CoinGecko API.
- **Loading & Error Handling:** Proper handling of loading, empty, and error states.
- **Mock Data Support:** Backend supports mock data for testing without depending on live API responses.

## Tech Stack

### Frontend
- Flutter
- Dart
- Riverpod (State Management)
- MVVM Architecture
- HTTP (API Integration)
- FL Chart (Charts)
- Shared Preferences (Local Storage)

### Backend
- Python
- FastAPI
- HTTPX
- Python-dotenv
- CoinGecko API

## Project Structure

```text
Crypto_research_app/
│
├── crypto_app/                 # Flutter frontend
│   ├── lib/
│   │   ├── config/
│   │   ├── models/
│   │   ├── repositories/
│   │   ├── services/
│   │   ├── viewmodels/
│   │   ├── views/
│   │   ├── utils/
│   │   └── widgets/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── crypto_backend/              # FastAPI backend
│   ├── main.py
│   ├── requirements.txt
│   └── .env.example
│
└── README.md
```

## Architecture

### Frontend – MVVM

The Flutter application follows the Model-View-ViewModel (MVVM) architecture.

- **Models:** Define the data structures used in the application.
- **Views:** Display the UI and handle user interactions.
- **ViewModels:** Manage application state, business logic, and API responses.
- **Repositories:** Coordinate data retrieval.
- **Services:** Handle backend API communication.

Riverpod is used for state management to separate UI components from application logic.

### Backend – FastAPI

The backend acts as an intermediary between the Flutter application and the CoinGecko API.

It handles API requests, processes responses, supports mock data, and provides structured responses to the frontend.

## Backend API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/health` | Check backend status |
| GET | `/coins` | Fetch cryptocurrency market list |
| GET | `/coins/{coin_id}` | Fetch individual coin details |
| GET | `/coins/{coin_id}/chart` | Fetch historical price data |
| GET | `/market/stats` | Fetch overall market statistics |

### API Query Parameters

**Coins endpoint:**
- `currency` – Display currency
- `page` – Pagination page
- `per_page` – Number of records
- `order` – Sorting order
- `search` – Search cryptocurrency

**Chart endpoint:**
- `currency` – Display currency
- `days` – Historical chart duration

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/sarathicdm/Crypto_research_app.git

cd Crypto_research_app
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd crypto_backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate the virtual environment on Windows:

```bash
venv\Scripts\activate
```

Install the required dependencies:

```bash
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Create a `.env` file inside the `crypto_backend` directory.

```env
COINGECKO_API_KEY=your_api_key_here
USE_MOCK_DATA=true
```

**Configuration:**

- `COINGECKO_API_KEY`: CoinGecko API key used for live API requests.
- `USE_MOCK_DATA`: Set to `true` to use mock data or `false` to use live API data.

Replace the placeholder API key with your actual API key when using live data.

### 4. Run the Backend

```bash
uvicorn main:app --reload
```

Backend URL:

```text
http://127.0.0.1:8000
```

Interactive API documentation:

```text
http://127.0.0.1:8000/docs
```

### 5. Flutter Setup

Open another terminal and navigate to the Flutter project:

```bash
cd crypto_app
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

**Important:** Configure the Flutter API base URL according to your running environment.

For Android Emulator:

```text
http://10.0.2.2:8000
```

For Flutter Web or a local desktop application:

```text
http://127.0.0.1:8000
```

For a physical Android device, use your computer's local network IP address and ensure both devices are connected to the same network.

## Running with Mock Data

The backend supports mock data to make testing easier without depending on live CoinGecko API responses.

Set the following in your backend `.env` file:

```env
USE_MOCK_DATA=true
```

Restart the backend after changing the configuration.

## Security Notes

- API keys and sensitive configuration values should be stored in the backend `.env` file.
- Do not upload the actual `.env` file to a public GitHub repository.
- Use `.env.example` to share the required environment variable names and placeholder values.

## Future Improvements

- User authentication.
- Cloud-based watchlist synchronization.
- Advanced cryptocurrency analytics.
- Additional technical indicators.
- Price alerts and notifications.

## Author

**Partha Sarathi**

Flutter Developer

GitHub: https://github.com/sarathicdm

---

**Project:** Crypto Research App  
**Frontend:** Flutter  
**Backend:** FastAPI  
**Market Data Provider:** CoinGecko API
