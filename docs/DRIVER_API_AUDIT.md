# Driver API audit

Audited against the live OpenAPI document at
`http://transport.wildlifeauctions.co.za:8081/api-json`.

## Authentication and files

| Endpoint | Mobile use | Request keys |
| --- | --- | --- |
| `POST /driver-auth/login` | Login | `phone`, `password` |
| `GET /driver-auth/profile` | Profile | Bearer token |
| `POST /file/upload` | Photos and signatures | multipart `file` |
| `POST /file/upload-video` | Loading and off-loading video | multipart `file` |

All secured driver endpoints receive the stored JWT as
`Authorization: Bearer <token>`.

## Schedule

| Endpoint | Mobile use |
| --- | --- |
| `GET /driver-auth/schedule/today` | Today and Completed tabs |
| `GET /driver-auth/schedule/upcoming` | Upcoming tab |

The documented schedule response keys consumed by the app are `_id`,
`buyerId`, `buyerName`, `address`, `auctionId`, `scheduleDate`,
`deliveryStatus`, `paymentStatus`, and `invoicePath`. The app also tolerates
the combined-delivery, customer contact, farm, and coordinate fields returned
by the current server even though they are not declared in the OpenAPI response
schema.

## Mobile delivery workflow

| Step | Endpoint | Request keys | Server status after success |
| --- | --- | --- | --- |
| Start loading | `PATCH /driver-auth/delivery/{id}/status` | `status: loading_in_progress` | `loading_in_progress` |
| Complete loading | `POST /driver-auth/delivery/{id}/start`, then `PATCH .../status` | Start payload below, then `status: loading_completed` | `loading_completed` |
| Start trip | `PATCH /driver-auth/delivery/{id}/status` | `status: in_delivery` | `in_delivery` |
| Register arrival | `PATCH /driver-auth/delivery/{id}/status` | `status: arrived_at_location` | `arrived_at_location` |
| Start off-loading | `PATCH /driver-auth/delivery/{id}/status` | `status: offloading_started` | `offloading_started` |
| Complete off-loading | `POST /driver-auth/delivery/{id}/end` | End payload below | `completed` |

Checklist entries use the exact keys `item` and `checked`.

The `/start` request uses `startOdometerReading`, `startVehiclePhotos`,
`startAnimalPhotos`, `onLoadAnimalsVideo`, `startLatitude`, `startLongitude`,
`vehicleChecklist`, `gameLoadingChecklist`, `managerSignature`, and
`otherSignature`.

The `/end` request uses `endAnimalPhotos`, `endAnimalVideos`,
`offLoadChecklist`, `clientSignature`, `endOdometerReading`, and `buyerId`.

## Direct status endpoint

`PATCH /driver-auth/delivery/{id}/status` accepts a JSON body containing
`status`. Documented values are:

- `pending`
- `ready`
- `started`
- `ongoing`
- `ended`
- `completed`
- `hold`
- `loading_in_progress`
- `loading_completed`
- `in_delivery`
- `arrived_at_location`
- `offloading_started`

The mobile workflow uses this endpoint for every intermediate phase. It does
not call `start-loading`, `complete-loading`, `start-trip`,
`at-delivery-location`, `start-offloading`, or `complete-offloading`.

## Location integration contracts

The Flutter app now consumes the contracts agreed in
`FIREBASE_LOCATION_TRACKING_HANDOFF.md`. These endpoints must be supplied and
documented by the NestJS backend:

| Endpoint | Mobile use | Request keys |
| --- | --- | --- |
| `POST /driver-auth/delivery/{id}/location` | Submit an active-trip reading | `latitude`, `longitude`, `accuracyMetres`, `recordedAt` |
| `PUT /driver-auth/delivery/{id}/customer-location` | Persist and mirror a customer pin | `buyerId`, `latitude`, `longitude`, `accuracyMetres`, `capturedAt` |

Both endpoints use the existing driver bearer token. The app queues driver
readings while offline. Customer-pin saves are interactive and report failures
immediately instead of being queued.
