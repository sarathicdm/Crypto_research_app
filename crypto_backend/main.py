import os
import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

load_dotenv()

app = FastAPI(title="Crypto Market Research API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

API_KEY = os.getenv("COINGECKO_API_KEY")
USE_MOCK_DATA = os.getenv("USE_MOCK_DATA", "false").lower() == "true"

COINGECKO_BASE_URL = "https://api.coingecko.com/api/v3"
HEADERS = {"x-cg-demo-api-key": API_KEY} if API_KEY else {}


MOCK_COINS = [
    {
        "id": "bitcoin", "symbol": "btc", "name": "Bitcoin",
        "image": "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
        "current_price": 67000, "market_cap": 1300000000000,
        "total_volume": 30000000000, "price_change_percentage_24h": 2.5,
    },
    {
        "id": "ethereum", "symbol": "eth", "name": "Ethereum",
        "image": "https://assets.coingecko.com/coins/images/279/large/ethereum.png",
        "current_price": 3500, "market_cap": 420000000000,
        "total_volume": 15000000000, "price_change_percentage_24h": -1.2,
    },
    {
        "id": "solana", "symbol": "sol", "name": "Solana",
        "image": "https://assets.coingecko.com/coins/images/4128/large/solana.png",
        "current_price": 180, "market_cap": 80000000000,
        "total_volume": 4000000000, "price_change_percentage_24h": 5.1,
    },
]

MOCK_COIN_DETAIL = {
    "id": "bitcoin", "symbol": "btc", "name": "Bitcoin",
    "description": "Bitcoin is the first decentralized cryptocurrency.",
    "image": {"large": "https://assets.coingecko.com/coins/images/1/large/bitcoin.png"},
    "market_data": {
        "current_price": {"usd": 67000},
        "market_cap": {"usd": 1300000000000},
        "total_volume": {"usd": 30000000000},
        "price_change_percentage_24h": 2.5,
        "high_24h": {"usd": 68000},
        "low_24h": {"usd": 66000},
        "circulating_supply": 19700000,
        "total_supply": 21000000,
    },
}

MOCK_CHART = {
    "prices": [
        [1700000000000, 65000], [1700003600000, 65500],
        [1700007200000, 66000], [1700010800000, 67000],
    ]
}

MOCK_MARKET_STATS = {
    "data": {
        "active_cryptocurrencies": 10000,
        "total_market_cap": {"usd": 2500000000000},
        "total_volume": {"usd": 100000000000},
        "market_cap_percentage": {"btc": 52.0, "eth": 17.0},
        "market_cap_change_percentage_24h_usd": 1.5,
    }
}


async def coingecko_get(path: str, params: dict = None) -> dict:
    url = f"{COINGECKO_BASE_URL}{path}"
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(url, headers=HEADERS, params=params)

        if response.status_code == 404:
            raise HTTPException(status_code=404, detail="Coin not found on CoinGecko.")
        if response.status_code == 429:
            raise HTTPException(status_code=429, detail="CoinGecko rate limit reached. Wait a moment and try again.")
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail=f"CoinGecko returned an error: {response.status_code}")

        return response.json()

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Request to CoinGecko timed out.")
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Network error: {str(e)}")

# Endpoints


@app.get("/health")
async def health():
    """Check whether the backend is running."""
    return {"status": "ok", "mock_mode": USE_MOCK_DATA}


@app.get("/coins")
async def get_coins(
    currency: str = Query(default="usd", description="Price currency, e.g. usd, eur"),
    per_page: int = Query(default=20, ge=1, le=250, description="Number of coins to return"),
    page: int = Query(default=1, ge=1, description="Page number"),
    order: str = Query(default="market_cap_desc", description="Sort order, e.g. market_cap_desc, volume_desc, price_asc"),
    search: str = Query(default=None, description="Filter coins by name or symbol"),
):
    """Return a list of cryptocurrencies with price and market data."""
    if USE_MOCK_DATA:
        coins = MOCK_COINS
        if search:
            coins = [c for c in coins if search.lower() in c["name"].lower() or search.lower() in c["symbol"].lower()]
        return {"source": "mock", "coins": coins}

    params = {
        "vs_currency": currency,
        "order": order,
        "per_page": per_page,
        "page": page,
        "sparkline": False,
        "price_change_percentage": "24h",
    }
    coins = await coingecko_get("/coins/markets", params)

    if search:
        coins = [c for c in coins if search.lower() in c["name"].lower() or search.lower() in c["symbol"].lower()]

    return {"source": "coingecko", "coins": coins}


@app.get("/coins/{coin_id}")
async def get_coin_detail(coin_id: str):
    """Return detailed information about a single cryptocurrency."""
    if USE_MOCK_DATA:
        return {"source": "mock", "coin": MOCK_COIN_DETAIL}

    params = {
        "localization": False,
        "tickers": False,
        "market_data": True,
        "community_data": False,
        "developer_data": False,
    }
    coin = await coingecko_get(f"/coins/{coin_id}", params)
    return {"source": "coingecko", "coin": coin}


@app.get("/coins/{coin_id}/chart")
async def get_coin_chart(
    coin_id: str,
    currency: str = Query(default="usd", description="Price currency"),
    days: int = Query(default=7, ge=1, le=365, description="Number of days of historical data"),
):
    """Return historical price data for a coin chart."""
    if USE_MOCK_DATA:
        return {"source": "mock", "chart": MOCK_CHART}

    params = {"vs_currency": currency, "days": days}
    chart = await coingecko_get(f"/coins/{coin_id}/market_chart", params)
    return {"source": "coingecko", "chart": chart}


@app.get("/market/stats")
async def get_market_stats():
    """Return overall crypto market statistics."""
    if USE_MOCK_DATA:
        return {"source": "mock", "stats": MOCK_MARKET_STATS["data"]}

    data = await coingecko_get("/global")
    return {"source": "coingecko", "stats": data.get("data", {})}
