# Crypto Market Research — FastAPI Backend

A simple Python backend that fetches real cryptocurrency data from CoinGecko and serves it to your Flutter app.

---

## Project Structure

```
crypto_backend/
├── main.py           # All API endpoints
├── requirements.txt  # Python dependencies
├── .env              # Your secret API key (never commit this)
├── .env.example      # Template showing required variables
└── README.md
```

---

## 1. Get a CoinGecko API Key

1. Go to https://www.coingecko.com/en/api and click **Get Your API Key**.
2. Sign up for a free **Demo** account.
3. Copy your API key from the dashboard.

> The free Demo key is enough for development. It allows ~30 calls/minute.

---

## 2. Configure `.env`

Open `.env` and replace the placeholder with your real key:

```
COINGECKO_API_KEY=CG-xxxxxxxxxxxxxxxxxxxx
USE_MOCK_DATA=false
```

Set `USE_MOCK_DATA=true` if you want to test without hitting the CoinGecko API (uses hardcoded sample data).

---

## 3. Install & Run

```bash
# 1. Move into the project folder
cd crypto_backend

# 2. Create a virtual environment
python -m venv venv

# 3. Activate it
# Windows:
venv\Scripts\activate
# macOS / Linux:
source venv/bin/activate

# 4. Install dependencies
pip install -r requirements.txt

# 5. Start the server
uvicorn main:app --reload
```

The server runs at: **http://127.0.0.1:8000**

---

## 4. Test the Endpoints

Open **http://127.0.0.1:8000/docs** in your browser.
FastAPI generates an interactive UI where you can call every endpoint and see the responses.

| Endpoint                    | Description                          |
|-----------------------------|--------------------------------------|
| `GET /health`               | Check if the server is running       |
| `GET /coins`                | List of coins with price & market data |
| `GET /coins/{coin_id}`      | Details for one coin (e.g. `bitcoin`) |
| `GET /coins/{coin_id}/chart`| Historical price data for a chart    |
| `GET /market/stats`         | Overall crypto market statistics     |

### Query Parameters for `GET /coins`

| Parameter  | Default          | Description                                      |
|------------|------------------|--------------------------------------------------|
| `currency` | `usd`            | Price currency (`usd`, `eur`, `gbp`, …)          |
| `per_page` | `20`             | Number of coins (1–250)                          |
| `page`     | `1`              | Page number                                      |
| `order`    | `market_cap_desc`| Sort: `market_cap_desc`, `volume_desc`, etc.     |
| `search`   | _(none)_         | Filter by name or symbol                         |

### Query Parameters for `GET /coins/{coin_id}/chart`

| Parameter  | Default | Description                        |
|------------|---------|------------------------------------|
| `currency` | `usd`   | Price currency                     |
| `days`     | `7`     | Days of history (1–365)            |

---

## 5. Connect to Your Flutter App

In your Flutter project, call the backend using the `http` package or `dio`.

```dart
// Example: fetch coin list
final response = await http.get(
  Uri.parse('http://127.0.0.1:8000/coins?per_page=20'),
);
```

> Use `http://10.0.2.2:8000` instead of `127.0.0.1` when running on an Android emulator.
> For a physical device, use your computer's local IP address (e.g. `http://192.168.1.x:8000`).

---

## 6. Response Format

Every endpoint wraps its data in a consistent envelope:

```json
{
  "source": "coingecko",
  "coins": [ ... ]
}
```

`source` will be `"coingecko"` for real data or `"mock"` when `USE_MOCK_DATA=true`.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `429 Too Many Requests` | CoinGecko rate limit hit | Wait ~60 seconds and retry |
| `404 Coin not found` | Wrong `coin_id` | Use IDs like `bitcoin`, `ethereum`, `solana` |
| `503 Network error` | No internet / CoinGecko is down | Check your connection |
