# KosCheck — Next Steps (Backend)

## 1. Enrich `/api/v1/discover` + `/api/v1/extract-url` Responses

### Problem

Both endpoints currently return only:

```json
{
  "listing_name": "...",
  "price": 1500000,
  "room_facilities": ["AC"],
  "shared_facilities": ["WiFi"],
  "listing_url": "https://mamikos.com/room/..."
}
```

The frontend `KosListingDto` therefore falls back to a static Unsplash placeholder for `imageUrl` and heuristically infers `location` from the URL slug.

### `aggregator_service.py` (`extract_listing_from_url`)

The `detail` JSON object already exists in the scrape result. Add these fields when `detail` is parsed:

| New field     | Mamikos source key                                          | Notes                             |
| ------------- | ----------------------------------------------------------- | --------------------------------- |
| `image_url`   | `detail.get("main_photo")` or `detail.get("photos", [])[0]` | First photo URL of the listing    |
| `address`     | `detail.get("address")` or `detail.get("location_label")`   | Full address string               |
| `description` | `detail.get("description")`                                 | Kos description text              |
| `coordinates` | `{"lat": detail.get("lat"), "lng": detail.get("lng")}`      | GPS coords if present             |
| `source`      | `"Mamikos"`                                                 | Platform name (hardcoded for now) |

Update the returned `result_data` dict in both the `detail`-parsed path and the BeautifulSoup fallback path:

```python
result_data = {
    "listing_name": listing_name,
    "price": price,
    "image_url": image_url,          # NEW
    "address": address,               # NEW
    "description": description,       # NEW
    "coordinates": coordinates,       # NEW
    "source": "Mamikos",              # NEW
    "room_facilities": room_facilities,
    "shared_facilities": shared_facilities,
    "listing_url": url,
}
```

### `models/validation.py`

Add optional fields to `KosListing` (model already has `address`, `description`, `photos`, `coordinates`):

```python
class KosListing(BaseModel):
    ...
    image_url: Optional[str] = None        # first photo URL (convenience alias)
    source: str = "Mamikos"
```

---

## 2. Riwayat Analisis — Save & Retrieve History

### Current State

- `POST /api/v1/validate-listing` already **saves** the result to Firestore as a background task via `save_validation_history`.
- There is **no GET endpoint** to retrieve those saved records.

### 2a. New `HistoryListItem` Model (`models/validation.py`)

```python
from datetime import datetime

class HistoryListItem(BaseModel):
    id: str
    listing_name: str
    area_name: str
    price: float
    anomaly_score: int
    status: str
    conclusion_summary: str
    image_url: Optional[str] = None
    created_at: datetime
```

### 2b. `db_service.py` — Fetch History

Add a new function to `db_service.py`:

```python
def _fetch_validation_history_sync(limit: int) -> list[dict[str, Any]]:
    client = get_firestore_client()
    if client is None:
        return []
    settings = get_settings()
    try:
        docs = (
            client.collection(settings.firestore_history_collection)
            .order_by("created_at", direction="DESCENDING")
            .limit(limit)
            .get(retry=None, timeout=5)
        )
        results = []
        for doc in docs:
            data = doc.to_dict() or {}
            data["id"] = doc.id
            results.append(data)
        return results
    except google_exceptions.GoogleAPICallError:
        return []

async def fetch_validation_history(limit: int = 20) -> list[dict[str, Any]]:
    return await asyncio.to_thread(_fetch_validation_history_sync, limit)
```

Also update `__all__` to export `fetch_validation_history`.

### 2c. `api/v1/validation.py` — New GET endpoint

```python
from app.services.db_service import fetch_validation_history

@router.get("/history", response_model=list[HistoryListItem])
async def get_validation_history(limit: int = 20) -> list[HistoryListItem]:
    raw_records = await fetch_validation_history(limit)
    items = []
    for rec in raw_records:
        form = rec.get("form_data", {})
        result = rec.get("result", {})
        items.append(HistoryListItem(
            id=rec["id"],
            listing_name=form.get("listing_name", ""),
            area_name=form.get("area_name", ""),
            price=form.get("price", 0),
            anomaly_score=result.get("anomaly_score", 0),
            status=result.get("status", ""),
            conclusion_summary=result.get("conclusion_summary", ""),
            image_url=form.get("image_url"),
            created_at=rec.get("created_at"),
        ))
    return items
```

### 2d. Return `record_id` from `POST /api/v1/validate-listing`

Currently the save is a fire-and-forget `BackgroundTask`, so the document ID is never returned to the client. Two options:

**Option A (Simple):** Await the save before returning and add `record_id` to `ValidationResult`:

```python
# In models/validation.py
class ValidationResult(BaseModel):
    ...
    record_id: Optional[str] = None   # NEW — Firestore doc ID
```

```python
# In api/v1/validation.py — replace background_tasks.add_task with:
record_id = await save_validation_history({...})
result.record_id = record_id
return result
```

**Option B (Non-blocking):** Keep the background task but have the frontend generate a client-side UUID and send it as `client_ref_id` in `listing_data`. The backend saves it, and later `GET /api/v1/history` can filter by it.

---

## 3. Optional Nice-to-Have Additions

### `GET /api/v1/history/{record_id}` — Single Record Detail

Returns the full saved payload (including `form_data`, `chat_analysis`, `visual_analysis`). Useful for a "detail" view in the history screen.

### Pagination for History

Add cursor-based pagination to `GET /api/v1/history`:

```
GET /api/v1/history?limit=20&start_after=<firestore_doc_id>
```

### User-scoped History (Firebase Auth)

Pass a `user_id` (from Firebase Auth UID) when saving and querying history so each user sees only their own records. Verify the Firebase ID token server-side using `firebase_admin.auth.verify_id_token(token)` and extract the UID from the decoded payload.

### Rating & Review Count in Discover

If Mamikos exposes `rating` and `review_count` in the `detail` JSON, forward them in the discover response so the `KosListing` `rating` and `reviewCount` fields are populated with real data instead of `0`.
