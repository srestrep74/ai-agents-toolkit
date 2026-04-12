# 840049: [SRT] TripHub — Observability: Rebooking Modify ingestion sending Business Event to Dynatrace

## Metadata
- **Type**: User Story
- **State**: New
- **Sprint**: Sprint 4b
- **Assignee**: Santiago
- **Story Points**: 3
- **Related Items**: [840129](https://copavsts.visualstudio.com/digital-products/_workitems/edit/840129)

---

## Description

As a Product Analyst and Observability team member, I want TripHub to emit a Dynatrace business event for `POST /triphub/rebooking/modify` using the existing enterprise CloudEvents model, so that we can analyze the modify request and final result **without creating a new payload structure**.

**Important constraint:** This US must reuse the observability model already defined by the team. Do not invent new sections or fields. Only populate fields that are already part of the existing model and that can be obtained from the following sources:
- Request payload
- Context (`ctx`)
- `displayBooking`
- `getDetailedTrip`
- `displayTicket`
- Final backend response

**References:**
- Telemetry Library: `copa-ebusiness-solutions-src/_git/telemetry-library`
- Events Wiki: `copa-ebusiness-solutions-src/_wiki/.../Booking-plan-multicity`

---

## Acceptance Criteria

- Emit a Dynatrace business event on every call to `POST /triphub/rebooking/modify`.
- Emit a **success event** when the orchestration returns HTTP 200.
- Emit an **error event** when the orchestration returns HTTP 4xx or 5xx.
- Bad requests captured by the frontend do not require a separate event.
- Execution must be **Fire and Forget** (async, non-blocking).
- The event schema must follow the CloudEvents standard (`specversion: "1.0"`).
- Do not create new event sections or modify the existing contract structure.

---

## Endpoint Under Instrumentation

| Field | Value |
|---|---|
| **Endpoint** | `POST /triphub/rebooking/modify` |
| **Content-Type** | `application/json` |
| **Success Response** | HTTP 200 — plain String |
| **Error Response** | HTTP 4xx/5xx — `ErrorResponse` |
| **OSL Ingest Endpoint** | `POST https://api-uat.copa.com/data/ingest/v1.0/business/event` |

---

## Request Payload

```json
{
  "pnr": "BAQFHJ",
  "surname": "GALVEZ",
  "confirmatedODs": [
    {
      "flightsOD": [
        {
          "departureDate": "2020-10-31T09:49:00",
          "arrivalDate": "2020-10-31T12:47:00",
          "origin": "PTY",
          "destination": "MEX",
          "flightNumber": "148",
          "originalDepartureDate": "2020-10-31T10:04:00",
          "originalArrivalDate": "2020-10-31T13:02:00",
          "originalFlightNumber": "148"
        }
      ],
      "selectedFlights": null,
      "classOD": "L"
    }
  ],
  "avoidSyncRemark": false,
  "typeModify": "WAIVER",
  "waiver": null
}
```

---

## Event Contract

### Fixed Field Mapping

| Field | Value / Source |
|---|---|
| `source` | `"cm.digital.mytrips.microservice.triphub.{{instanceName}}.{{environment}}"` |
| `type` | `"cm.digital.mytrips.srt_modify_success"` OR `"cm.digital.mytrips.srt_modify_error"` |
| `event.category` | `"cm.digital.mytrips"` (Constant) |
| `subject` | `"SRTModifyEvent"` (Constant) |
| `eventName` | `"modify"` (Constant) |
| `productInfo.productName` | `"SRT"` (Constant) |
| `productInfo.productCategory` | `"MyTrips"` (Constant) |
| `productInfo.service.serviceName` | `"Modify"` (Constant) |
| `productInfo.service.serviceCode` | `request.typeModify` |

### Dynamic Field Mapping

| Field | Source |
|---|---|
| `data.queryInfo.recordLocator` | `request.pnr` |
| `data.queryInfo.passengerLastName` | `request.surname` |
| `data.queryInfo.searchedItinerary[].flightNumber` | `request.confirmatedODs[].flightsOD[].flightNumber` |
| `data.queryInfo.searchedItinerary[].departureAirportCode` | `request.confirmatedODs[].flightsOD[].origin` |
| `data.queryInfo.searchedItinerary[].arrivalAirportCode` | `request.confirmatedODs[].flightsOD[].destination` |
| `data.queryInfo.searchedItinerary[].departureDate` | `request.confirmatedODs[].flightsOD[].departureDate` |
| `data.queryInfo.searchedItinerary[].arrivalDate` | `request.confirmatedODs[].flightsOD[].arrivalDate` |
| `data.bookingInfo.airlineCode` | `trip.flights.head.airlineCode` |
| `data.bookingInfo.bookingCreationDate` | `booking.createDateTime` OR `trip.createDateTime` |
| `data.bookingInfo.recordLocator` | `request.pnr` |
| `data.channelId` | Configured `channelId` for the flow (`"WEBMMB"`) |
| `data.correlationId` | `ctx.correlationId` |
| `data.errorInfo.statusCode` | HTTP status returned by TripHub *(error event only)* |
| `data.errorInfo.errorCode` | `ErrorResponse.code` *(error event only)* |
| `data.errorInfo.errorMessage` | `ErrorResponse.message` *(error event only)* |

---

## Event Payload Examples

### Success Event

```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "source": "cm.digital.mytrips.microservice.triphub.{{instanceName}}.{{environment}}",
    "type": "cm.digital.mytrips.srt_modify_success",
    "event.category": "cm.digital.mytrips",
    "specversion": "1.0",
    "subject": "SRTModifyEvent",
    "datacontenttype": "application/json",
    "data": {
      "queryInfo": {
        "recordLocator": "BAQFHJ",
        "passengerLastName": "GALVEZ",
        "searchedItinerary": [
          {
            "flightNumber": 148,
            "departureAirportCode": "PTY",
            "departureDate": "2020-10-31T09:49:00",
            "arrivalDate": "2020-10-31T12:47:00",
            "arrivalAirportCode": "MEX"
          }
        ]
      },
      "bookingInfo": {
        "airlineCode": "CM",
        "bookingCreationDate": "2020-10-26T18:11:00Z",
        "recordLocator": "BAQFHJ"
      },
      "productInfo": {
        "productName": "SRT",
        "productCategory": "MyTrips",
        "service": {
          "serviceName": "Modify",
          "serviceCode": "WAIVER"
        }
      },
      "channelId": "WEBMMB",
      "correlationId": "778668b4-f893-4389-b950-5d84f513c329",
      "eventName": "modify",
      "eventStatus": "success"
    }
  }
]
```

### Error Event

```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "source": "cm.digital.mytrips.microservice.triphub.{{instanceName}}.{{environment}}",
    "type": "cm.digital.mytrips.srt_modify_error",
    "event.category": "cm.digital.mytrips",
    "specversion": "1.0",
    "subject": "SRTModifyEvent",
    "datacontenttype": "application/json",
    "data": {
      "queryInfo": {
        "recordLocator": "BAQFHJ",
        "passengerLastName": "GALVEZ",
        "searchedItinerary": [
          {
            "flightNumber": 148,
            "departureAirportCode": "PTY",
            "departureDate": "2020-10-31T09:49:00",
            "arrivalDate": "2020-10-31T12:47:00",
            "arrivalAirportCode": "MEX"
          }
        ]
      },
      "bookingInfo": {
        "recordLocator": "BAQFHJ"
      },
      "productInfo": {
        "productName": "SRT",
        "productCategory": "MyTrips",
        "service": {
          "serviceName": "Modify",
          "serviceCode": "WAIVER"
        }
      },
      "errorInfo": {
        "statusCode": 500,
        "errorCode": "9000",
        "errorMessage": "Serialization DXC Error"
      },
      "channelId": "WEBMMB",
      "correlationId": "778668b4-f893-4389-b950-5d84f513c329",
      "eventName": "modify",
      "eventStatus": "error"
    }
  }
]
```

---

## Tasks / Child Items
- [ ] 840129: *(Title to be fetched from ADO)*

## Relevant Comments
*(No comments found)*
