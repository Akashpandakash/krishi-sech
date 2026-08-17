# Market — `/api/market`

The product catalogue: seeds, fertilizers, and tools. Source:
[`server/src/market/`](../../server/src/market/).

Shared envelope, error codes, and conventions: [README](README.md).
**Requires `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/products` | Browse the catalogue |
| GET | `/products/:id` | One product |

This router is **optionally mounted** — deployments without a market service
answer `404 NOT_FOUND` for the whole path.

Only **active** products are visible here. Delisted ones remain in storage for
order history but never appear in either endpoint. Admins manage the catalogue
through [`/api/admin/products`](admin.md).

## GET `/products`

```http
GET /api/market/products?category=seeds&search=paddy&language=bn
Authorization: Bearer <accessToken>
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `category` | enum | | `seeds`, `fertilizers`, `tools` |
| `search` | string | | 1–80 chars. Matches the **English** name and the vendor |
| `language` | enum | | One of the 23 app locales |

`search` matches against the English name and the vendor only — a Bengali query
string will not match a Bengali product name. Search the resolved list
client-side if you need in-language matching.

Response `200`:

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "products": [
      {
        "id": "p-swarna-seed-10kg",
        "name": "স্বর্ণ ধানের বীজ",
        "description": "উচ্চ ফলনশীল আমন ধানের বীজ, ১০ কেজি ব্যাগ।",
        "category": "seeds",
        "price": 850,
        "unit": "bag",
        "stockQuantity": 42,
        "vendor": "Nadia Agro Supplies",
        "isAvailable": true
      }
    ],
    "count": 1
  }
}
```

## GET `/products/:id`

```http
GET /api/market/products/p-swarna-seed-10kg?language=bn
```

Response `200` with a single product object in `data` — the same shape as one
entry above, not wrapped in `products`.

Returns `404 PRODUCT_NOT_FOUND` when the ID is unknown **or the product is
inactive**. A delisted product is indistinguishable from a nonexistent one, so a
deep link into a product that was pulled shows "not found" rather than
"unavailable".

## The product object

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | Stable catalogue ID |
| `name` | **string** | Already resolved to one language |
| `description` | **string** | Already resolved to one language |
| `category` | enum | `seeds`, `fertilizers`, `tools` |
| `price` | integer | **Whole rupees** |
| `unit` | enum | `bag`, `pack`, `piece`, `kg`, `litre` |
| `stockQuantity` | integer | Units in stock |
| `vendor` | string | Seller name |
| `isAvailable` | boolean | Computed — `stockQuantity > 0` |

`price` is whole rupees for **one `unit`** — one bag, one piece, one kg. It is
an integer, never a decimal, so no currency rounding is needed.

`isAvailable` is derived, not stored. Trust it over comparing `stockQuantity`
yourself. A product can be listed with `stockQuantity: 0`, in which case it
appears in the catalogue with `isAvailable: false` — show it as out of stock
rather than hiding it, since that is what the seller intended.

The response carries no `createdAt`/`updatedAt`. Those exist on the admin view
of the same record but are stripped here.

## Localization

`name` and `description` are stored as per-locale maps with a required `en` key,
but **this endpoint always returns plain strings**. The server resolves them
before responding, so the client never deals with the map.

Resolution order:

1. Exact match on the requested `language`.
2. The base subtag — `pa_IN` and `pa-IN` both fall back to `pa`, since a seller
   writing Punjabi does not distinguish regions.
3. `en`, which every product is required to have.

Omitting `language` resolves straight to English. So the parameter is not
optional in practice: leave it off and Bengali-reading farmers get an English
catalogue.

Pass the farmer's `preferredLanguage` from [Profile](profile.md) directly — this
module accepts all 23 app locales, unlike [AI](ai.md) and the recommendation
endpoints, which take only `bn`/`en`/`hi`.

Because untranslated fields silently fall back to English, a partially
translated catalogue produces a mixed-language list. That is intended — a
product name in English beats no product — but it means you cannot infer the
farmer's language from the text you got back.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Unknown `category`, unsupported `language`, or an over-long `search` |
| 404 | `PRODUCT_NOT_FOUND` | Unknown ID, or the product is inactive |
| 404 | `NOT_FOUND` | The router is not mounted on this deployment |

## Not in this API

There is no cart, order, checkout, or payment endpoint. The market is a
catalogue the farmer browses; transactions happen off-platform with the vendor.
