# Caricature Maker Photo – Backend Integration Spec

**Purpose:** This document describes the graphics pipeline and API contract of the iOS Caricature Maker app so a backend (e.g. Modal, RunPod Serverless) can be designed to provide the stylization step.

---

## 1. App Overview

The app produces **stylized caricatures** from user photos in two stages:
1. **On-device (iOS):** Face detection, geometric warping (caricature exaggeration)
2. **Server:** Stylization (cartoon, sketch, pop art, etc.) applied to the warped image

The server receives an **already-warped** face image (geometric exaggeration done locally) and returns a **stylized** version.

---

## 2. Graphics Pipeline (What Happens Where)

```
User selects photo
       │
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  ON-DEVICE (iOS)                                                  │
│                                                                   │
│  1. Face detection (Vision / VNDetectFaceLandmarksRequest)        │
│     - Detects faces + landmarks (eyes, nose, mouth, jaw, contour)│
│     - User picks face if multiple                                │
│                                                                   │
│  2. Geometric warping (CoreImage)                                 │
│     - CIBumpDistortion at eyes, nose, mouth                       │
│     - CIPinchDistortion at jaw/face contour                       │
│     - Intensity controlled by params (0..1)                       │
│     - Output: warped face photo (JPEG)                            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
       │
       │  Upload: warped JPEG + style_id + params
       ▼
┌──────────────────────────────────────────────────────────────────┐
│  SERVER (Modal / RunPod / etc.)                                   │
│                                                                   │
│  3. Stylization                                                   │
│     - Input: warped face image + style_id                         │
│     - Apply style (cartoon, sketch, pop_art, watercolor, comic)   │
│     - Output: stylized image (JPEG/PNG)                           │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
       │
       │  Result URL
       ▼
App displays result, saves to Photos, adds to history
```

---

## 3. Local Warping (Server Does NOT Do This)

The app performs geometric caricature warping locally using CoreImage:

- **CIBumpDistortion** at landmark centers: left eye, right eye, nose, mouth  
  - Scale derived from params (eyes, nose, mouth) and global intensity  
  - Radius: ~6–10% of image width per region  
- **CIPinchDistortion** at face contour center for jaw  
  - Scale derived from jaw param  

Params are in 0..1. A “neutral” value (0.5) leaves features mostly unchanged. Higher values exaggerate. The server receives the **final warped image**; it does not need face landmarks or warp logic.

---

## 4. API Contract

Base URL is configured in the app (e.g. `https://your-api.com`). The client appends paths below.

### 4.1 Create Job

**POST** `{baseURL}/v1/jobs`

**Content-Type:** `multipart/form-data`

| Field     | Type   | Description                                                    |
|-----------|--------|----------------------------------------------------------------|
| `image`   | File   | Warped face image, JPEG, filename `image.jpg`                  |
| `params`  | JSON   | `CaricatureWarpParams` (metadata; optional for stylization)   |
| `style_id`| String | Style identifier (see below)                                  |

**params JSON structure:**
```json
{
  "intensity": 0.5,
  "eyes": 0.5,
  "nose": 0.5,
  "mouth": 0.5,
  "jaw": 0.5
}
```
(All values 0..1. Server may ignore these; they mainly document the warp used.)

**style_id values (server must support):**
- `cartoon`
- `sketch`
- `pop_art`
- `watercolor`
- `comic`

**Response (200):**
```json
{
  "id": "job-uuid-string"
}
```

---

### 4.2 Poll Job Status

**GET** `{baseURL}/v1/jobs/{id}`

**Response (200) – pending:**
```json
{
  "status": "pending",
  "result_url": null,
  "error": null
}
```

**Response (200) – succeeded:**
```json
{
  "status": "succeeded",
  "result_url": "https://storage.example.com/results/xxx.jpg",
  "error": null
}
```

**Response (200) – failed:**
```json
{
  "status": "failed",
  "result_url": null,
  "error": "Optional error message"
}
```

**Polling behavior:**
- Client polls with exponential backoff (1s → 10s max)
- Up to ~60 attempts before timeout
- `result_url` must be a direct, publicly GET-able URL to the result image

---

### 4.3 Download Result

**GET** `{result_url}`

- Client fetches image bytes directly from this URL
- Expects image/jpeg or image/png
- No auth expected (URL is assumed pre-signed or public)

---

## 5. Image Formats

| Stage       | Format  | Notes                                           |
|------------|---------|-------------------------------------------------|
| Upload     | JPEG    | Quality ~0.9, warped face, variable resolution |
| Result URL | JPEG/PNG| Stylized output; client accepts either          |

Uploaded images are typically phone-resolution (e.g. 1000–4000 px). Server may resize for inference.

---

## 6. Server Responsibilities (Summary)

1. Accept multipart POST with `image`, `params`, `style_id`.
2. Create async job; return job `id`.
3. Process: apply stylization model for given `style_id` to the warped image.
4. Store result; generate public or pre-signed URL.
5. Expose GET endpoint that returns `status`, `result_url`, `error`.
6. `result_url` must serve the final stylized image.

---

## 7. Stylization Models (Backend Choices)

The server chooses how to implement each `style_id`. Examples:
- Cartoon/Sketch: image-to-image models (e.g. ControlNet, InstructPix2Pix, style transfer)
- Pop art: style transfer or LoRAs
- Watercolor: style transfer
- Comic: cartoon/comic models

The warped input is already a caricature; the server only needs to stylize it.

---

## 8. Suggested Hosting

- **Modal:** Python, GPU on-demand, good for dev speed.
- **RunPod Serverless:** GPU endpoints, pay-per-use.
- Both support async workflows and public URL results.
