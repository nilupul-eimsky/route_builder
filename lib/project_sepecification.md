# Route Generator Flutter MVP

## 1. Project Goal

Build a production-quality Flutter MVP mobile application called **Route Builder**.

The app is an **offline-first route creation and GPS tracking application**.

The user must be able to:

1. Create a route by selecting locations/coordinates on a map.
2. Save the planned route locally.
3. View the route on a map.
4. Start a tracking session for a route.
5. Periodically receive GPS location updates.
6. Store accepted GPS points locally.
7. Pause and resume tracking.
8. Avoid storing duplicate/stationary GPS points.
9. View the planned route and actual GPS track in real time.
10. View route/tracking data as formatted JSON.
11. Export route/tracking data as JSON and GeoJSON files.
12. Configure the location recording interval from Settings.
13. Correctly handle location permissions and location services.

There is **NO backend** in this MVP.

Everything must work locally on the device.

---

# 2. Important Scope Clarification

## Route creation

Do NOT implement freehand/manual route drawing.

The user creates a route by selecting locations/coordinates on the map.

The MVP should support:

- Tapping/selecting a location on the map.
- Using the current GPS location as a selected point.
- Adding selected locations sequentially to the route.
- Showing the selected points on the map.
- Connecting the selected points with a polyline.
- Removing the last selected point.
- Clearing the route.
- Saving the route.

The exact route-generation algorithm should remain simple for the MVP.

The application is primarily creating a **sequence of geographic coordinates** that represents a planned route.

Do not add a full turn-by-turn routing engine unless explicitly requested later.

---

# 3. Technology

Use:

- Flutter
- Dart
- Material 3
- BLoC/Cubit
- Clean Architecture
- Google Maps Flutter
- Geolocator
- Isar or Hive for local persistence
- Path Provider where needed
- Share Plus for file sharing
- Intl for date/time
- A lightweight GeoJSON serialization approach

Prefer the latest stable package APIs compatible with the selected Flutter SDK.

Avoid unnecessary dependencies.

---

# 4. Architecture

Use Clean Architecture with clear separation of concerns.

Recommended structure:

```text
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── services/
│   ├── utils/
│   └── extensions/
│
├── data/
│   ├── datasources/
│   │   └── local/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── bloc/
│   ├── cubit/
│   ├── pages/
│   ├── widgets/
│   └── routes/
│
└── main.dart
```

Preferred dependency flow:

```text
UI
 ↓
BLoC/Cubit
 ↓
Use Case
 ↓
Repository
 ↓
Local Data Source / Device Service
```

Do not place business logic directly inside widgets.

---

# 5. Main Screens

Implement these screens:

1. Routes/Home
2. Create Route
3. Route Details
4. Tracking / Drive Mode
5. Tracking Summary
6. JSON Viewer
7. Settings

Use a clean Material 3 design.

---

# 6. Home / Routes Screen

Screen title:

```text
Routes
```

Show all locally stored routes.

Each route should display:

- Route name
- Created date/time
- Number of planned coordinates
- Planned route distance
- Tracking status if a session exists
- Tracking distance if completed

Possible statuses:

```text
Created
In Progress
Paused
Completed
```

Actions:

```text
Open
Start
Export
Delete
```

Provide a prominent:

```text
+ Create Route
```

button.

---

# 7. Create Route

Screen title:

```text
Create Route
```

The main UI is a Google Map.

## User flow

1. Open map.
2. User searches or navigates to a location.
3. User taps a location on the map.
4. Show a marker at the selected coordinate.
5. User confirms/adds the location.
6. The coordinate becomes a route point.
7. User continues selecting additional locations.
8. Draw a polyline connecting the route points.
9. User enters a route name.
10. User saves the route.

Example:

```text
Map

       ● Point 1
          \
           ● Point 2
              \
               ● Point 3

--------------------------------
Selected Points: 3
Distance: 2.4 km

[ Undo Last ] [ Clear ]

Route Name
[ Colombo Route ]

[ Save Route ]
--------------------------------
```

## Current Location

Provide:

```text
Use Current Location
```

When pressed:

- Request location permission.
- Check location services.
- Get current GPS location.
- Show the coordinate on the map.
- Allow the user to add it as a route point.

The user should still be able to tap/select another location.

---

# 8. Route Point Selection

Use a clear interaction.

When the user taps the map:

```text
Selected location
Latitude: 6.927100
Longitude: 79.861200
```

Show a confirmation action:

```text
[ Add Point ]
```

Do not immediately save every map tap as a route point.

Only confirmed points should become part of the route.

Provide:

```text
Undo Last
Clear All
```

Do not implement freehand drawing.

---

# 9. Planned Route Model

Create a strongly typed route entity.

Example:

```json
{
  "id": "route_001",
  "name": "Colombo Route",
  "createdAt": "2026-09-16T08:30:00Z",
  "coordinates": [
    {
      "latitude": 6.9271,
      "longitude": 79.8612
    },
    {
      "latitude": 6.9275,
      "longitude": 79.8620
    }
  ]
}
```

Use typed Dart models/entities.

Do not pass raw dynamic Maps throughout the application.

---

# 10. GeoJSON

Every route must be exportable as valid GeoJSON.

Use:

```json
{
  "type": "Feature",
  "properties": {
    "id": "route_001",
    "name": "Colombo Route"
  },
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [79.8612, 6.9271],
      [79.8620, 6.9275]
    ]
  }
}
```

## Critical GeoJSON rule

GeoJSON coordinates are:

```text
[longitude, latitude]
```

NOT:

```text
[latitude, longitude]
```

Create a dedicated GeoJSON serializer.

Do not mix Google Maps `LatLng` ordering with GeoJSON ordering.

---

# 11. Route Validation

Before saving:

- Route name must not be empty.
- At least 2 route points are required.
- Coordinates must be valid.
- Route should not contain invalid/null coordinates.

Show appropriate validation messages.

Example:

```text
A route must contain at least 2 points.
```

---

# 12. Route Details

When opening a saved route, display:

## Map

Show:

- Planned route polyline
- Start marker
- End marker
- All selected route points
- Current location if tracking is active
- Actual GPS track if a session exists

Controls:

- Zoom
- My Location
- Fit Route
- Normal/Drive mode

## Information

Display:

```text
Route Name
Created Date
Planned Distance
Points
Tracking Sessions
```

Actions:

```text
Start Tracking
View JSON
Export GeoJSON
Export JSON
Delete
```

---

# 13. Planned Route vs Actual Track

Keep these concepts completely separate.

## Planned Route

Created by the user:

```text
plannedRouteCoordinates
```

## Actual GPS Track

Recorded while the user is moving:

```text
trackingCoordinates
```

The user may deviate from the planned route.

The application must not overwrite the planned route with GPS tracking data.

The map can display both simultaneously.

Example:

```text
Planned Route
━━━━━━━━━━━━━━

Actual Track
- - - - - - - -
```

---

# 14. Start Tracking

The user selects:

```text
Start Tracking
```

Before starting:

1. Request location permission.
2. Check location services.
3. Check required permissions.
4. Create a new tracking session.
5. Save the session locally.
6. Start receiving GPS updates.

Then open the Tracking / Drive Mode screen.

---

# 15. Tracking Session

Create a separate tracking session entity.

Example:

```json
{
  "id": "session_001",
  "routeId": "route_001",
  "startedAt": "2026-09-16T08:30:00Z",
  "endedAt": null,
  "status": "tracking",
  "totalDistanceMeters": 0,
  "points": []
}
```

Possible statuses:

```text
tracking
paused
completed
```

---

# 16. GPS Point Model

Each accepted GPS point should contain:

```json
{
  "latitude": 6.9271,
  "longitude": 79.8612,
  "timestamp": "2026-09-16T08:45:23Z",
  "accuracy": 8.5,
  "speed": 12.3
}
```

Fields:

- latitude
- longitude
- timestamp
- accuracy
- speed

Altitude may be stored if available.

---

# 17. Location Update Architecture

Do NOT rely only on:

```dart
Timer.periodic()
```

as the GPS source.

Use the operating system location API through `geolocator`.

Recommended flow:

```text
OS Location Updates
        ↓
Location Service
        ↓
Tracking Controller
        ↓
Interval / Recording Filter
        ↓
Accuracy Validation
        ↓
Movement Validation
        ↓
Persist Point
        ↓
Update Map
```

The configured interval should control how frequently points are **recorded**, while the OS can provide location updates independently.

Design this so background tracking can be added later.

---

# 18. Configurable Recording Interval

Settings must contain:

```text
Location Update Interval
```

Use a dropdown.

Options:

```text
1 second
5 seconds
10 seconds
15 seconds
30 seconds
1 minute
5 minutes
```

Default:

```text
5 seconds
```

Persist the selected value locally.

The tracking service must use this configuration.

Do not hard-code the interval inside the tracking BLoC.

---

# 19. Duplicate / Stationary GPS Filtering

This is a critical requirement.

Do not store every GPS update.

When a new GPS update arrives:

```text
New GPS point
      ↓
Check accuracy
      ↓
Check recording interval
      ↓
Get last STORED point
      ↓
Calculate geographic distance
      ↓
If movement < threshold
      ↓
Ignore
      ↓
If movement >= threshold
      ↓
Persist point
```

Default minimum movement:

```text
5 meters
```

Use geographic distance calculation such as:

```dart
Geolocator.distanceBetween(
  previous.latitude,
  previous.longitude,
  current.latitude,
  current.longitude,
);
```

Example:

```text
Previous:
6.927100, 79.861200

Current:
6.927101, 79.861201

Distance < 5m

Result:
Ignore
```

If:

```text
Distance >= 5m
```

then store the point.

The threshold must be a constant/configuration value so it can easily be changed.

---

# 20. Accuracy Validation

Default:

```text
Maximum accepted accuracy = 50 meters
```

If:

```text
current.accuracy > 50
```

do not store the point.

The current UI should show:

```text
GPS Accuracy: 8m
```

If accuracy is poor:

```text
Poor GPS accuracy
```

Do not silently save obviously inaccurate coordinates.

Make the threshold easy to configure.

---

# 21. Recording Interval + Movement Filter

Both rules must be applied.

Example:

```text
GPS update arrives
        ↓
Has recording interval elapsed?
        ↓
NO → Ignore
        ↓
YES
        ↓
Accuracy acceptable?
        ↓
NO → Ignore
        ↓
YES
        ↓
Moved at least 5 meters?
        ↓
NO → Ignore
        ↓
YES
        ↓
Store point
```

The comparison for movement must always be against the **last stored point**, not simply the last received GPS update.

---

# 22. Pause Tracking

Tracking screen must have:

```text
Pause
```

When paused:

- Stop recording points.
- Keep the tracking session.
- Keep existing points.
- Keep elapsed/session information as appropriate.
- Show `PAUSED`.

Example:

```text
PAUSED

Points: 184
Distance: 12.4 km

[ Resume ]
[ Stop Tracking ]
```

---

# 23. Resume Tracking

When Resume is pressed:

- Resume receiving GPS updates.
- Apply interval/accuracy/movement validation again.
- Continue adding accepted points.
- Do not generate fake points between pause and resume.

---

# 24. Stop Tracking

When Stop is selected, show confirmation:

```text
Stop tracking?

The current tracking session will be saved locally.
```

After confirmation:

- Stop location processing.
- Set session status to `completed`.
- Save end timestamp.
- Calculate final statistics.
- Persist the session.

---

# 25. Tracking Statistics

Calculate:

- Total distance
- Duration
- Number of stored GPS points
- Average speed
- Start time
- End time

Example:

```text
Route Statistics

Distance
12.4 km

Duration
01:32:15

GPS Points
438

Average Speed
8.1 km/h

Start
08:30 AM

End
10:02 AM
```

Distance must be calculated using the accepted/stored GPS points.

Do not calculate distance from rejected GPS updates.

---

# 26. Tracking Screen / Drive Mode

The main tracking screen should be map-focused.

Example:

```text
--------------------------------
Tracking

           MAP

    Planned Route
    ━━━━━━━━━━━━━

    Actual Track
    - - - - - -

         ●
    Current Location

--------------------------------
Distance       Duration

12.4 km        01:25:32

GPS Accuracy
8m

Status
● TRACKING

[ Pause ]

[ Stop ]
--------------------------------
```

---

# 27. Normal Map Mode

Normal mode:

- User can pan/zoom freely.
- Show planned route.
- Show actual track when available.
- Show markers.
- Show current location if available.

---

# 28. Drive Mode

Drive mode:

- Map automatically follows current location.
- Show current location prominently.
- Show planned route.
- Show actual GPS trail.
- Show distance travelled.
- Show elapsed time.
- Show GPS accuracy.
- Provide Follow Location control.

Example:

```text
[ Following Location ✓ ]
```

If the user manually moves the map:

- Stop automatic camera following.
- Allow the user to enable Follow Location again.

Do not constantly force the camera to the user's position if they have intentionally moved the map.

---

# 29. Local Persistence

There is no backend.

Persist locally:

## Routes

```text
id
name
createdAt
coordinates
```

## Tracking Sessions

```text
id
routeId
status
startedAt
endedAt
points
distance
duration
```

## Settings

```text
locationRecordingInterval
```

Persist each accepted GPS point immediately.

Do not keep the complete tracking session only in memory.

---

# 30. App Restart During Tracking

The application must be resilient to app restart.

If tracking is active and the application restarts:

1. Load local tracking sessions.
2. Detect an unfinished session.
3. Show:

```text
Unfinished tracking session found.

[ Resume ]
[ Discard ]
```

If Resume is selected:

- Restore the session.
- Restore stored points.
- Continue tracking.

If Discard is selected:

- Confirm with the user.
- Mark/delete the unfinished session appropriately.

Do not lose already persisted points.

---

# 31. JSON Viewer

Create:

```text
JSON View
```

Display formatted JSON.

Requirements:

- Pretty printed
- Scrollable
- Monospace font
- Copy button
- Share button

Example:

```json
{
  "route": {
    "id": "route_001",
    "name": "Colombo Route"
  },
  "tracking": {
    "status": "completed",
    "points": []
  }
}
```

Do not display Dart's `toString()` output.

Use valid JSON serialization.

---

# 32. Export

Because there is no backend, export is a core feature.

Provide:

```text
Export
```

Options:

```text
GeoJSON
JSON
```

Generate actual files.

Examples:

```text
colombo_route.geojson
colombo_route.json
```

Use the native share sheet where possible.

The user should be able to share through:

- WhatsApp
- Email
- Files
- Google Drive
- AirDrop
- Other installed apps

Do not create a proprietary export format.

---

# 33. GeoJSON Export Structure

For a planned route:

```json
{
  "type": "Feature",
  "properties": {
    "id": "route_001",
    "name": "Colombo Route"
  },
  "geometry": {
    "type": "LineString",
    "coordinates": [
      [79.8612, 6.9271],
      [79.8620, 6.9275]
    ]
  }
}
```

For tracking export, include the actual tracking coordinates in a clearly defined structure.

A possible structure is:

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "type": "planned_route"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": []
      }
    },
    {
      "type": "Feature",
      "properties": {
        "type": "actual_track"
      },
      "geometry": {
        "type": "LineString",
        "coordinates": []
      }
    }
  ]
}
```

Use a valid and consistent structure.

---

# 34. Settings

Create a Settings page.

Required setting:

```text
Location Recording Interval
```

Dropdown:

```text
1 second
5 seconds
10 seconds
15 seconds
30 seconds
1 minute
5 minutes
```

Default:

```text
5 seconds
```

Persist it locally.

Also display useful information:

```text
Minimum movement: 5m
Maximum GPS accuracy: 50m
```

These can remain developer-configurable constants for the MVP rather than user-editable settings.

---

# 35. Location Permissions

Handle location permissions properly.

Cases:

## Permission not requested

Request permission.

## Permission denied

Show an explanation and provide retry.

## Permanently denied

Show:

```text
Location permission is required for route tracking.

Please enable Location permission from Settings.
```

Provide a button to open application settings where supported.

## Location services disabled

Show:

```text
Location services are disabled.

Please enable GPS/location services to continue.
```

Do not repeatedly request permission after permanent denial.

Handle Android and iOS separately where platform behavior differs.

---

# 36. Android Configuration

Configure required Android location permissions.

At minimum, configure appropriate foreground location permission for the MVP.

If background tracking is not implemented, do not add unnecessary background location permissions.

Keep the architecture extensible for future background tracking.

---

# 37. iOS Configuration

Configure the required location usage description in `Info.plist`.

For example:

```text
NSLocationWhenInUseUsageDescription
```

Use the correct permission level for the implemented functionality.

Do not claim background tracking support unless it is actually implemented and configured.

---

# 38. Google Maps

Use Google Maps for:

- Route creation
- Route details
- Tracking
- Drive mode

Do not hard-code API keys into Dart source code.

Clearly document where API keys need to be configured for:

- Android
- iOS

The app should compile after the developer adds valid Google Maps API keys.

---

# 39. Map Performance

The application may eventually contain thousands of coordinates.

Therefore:

- Avoid rebuilding the entire screen on every GPS update.
- Avoid recreating every marker unnecessarily.
- Update polylines efficiently.
- Store GPS points incrementally.
- Do not serialize the entire dataset into JSON on every GPS update.
- Use efficient BLoC state updates.
- Keep the map responsive.

---

# 40. UI/UX

Use Material 3.

Provide:

- Light theme
- Dark theme
- Responsive layout
- Empty states
- Loading states
- Error states
- Confirmation dialogs
- Snackbars
- Bottom sheets where useful

Keep the UI professional and simple.

Avoid unnecessary animations.

The map should be the primary visual component of route-related screens.

---

# 41. Home Screen Example

```text
--------------------------------
Routes

My Routes

┌──────────────────────────────┐
│ Colombo City Route           │
│ Created: Sep 16, 2026        │
│ 12.4 km • 24 points          │
│                              │
│ [ Open ]        [ Start ]    │
└──────────────────────────────┘

┌──────────────────────────────┐
│ Ratnapura Route               │
│ Created: Sep 15, 2026        │
│ 8.2 km • 18 points           │
│                              │
│ [ Open ]        [ Start ]    │
└──────────────────────────────┘

                         (+)
                    Create Route
--------------------------------
```

---

# 42. Create Route UX

Preferred flow:

```text
Create Route
      ↓
Map opens
      ↓
User taps location
      ↓
Selected coordinate marker appears
      ↓
User confirms "Add Point"
      ↓
Point added to route
      ↓
User selects next location
      ↓
Polyline updated
      ↓
User saves route
```

Also support:

```text
Use Current Location
```

as an alternative way to select a route point.

---

# 43. Validation / Edge Cases

Handle:

1. Empty route name.
2. Fewer than 2 route points.
3. Invalid coordinates.
4. Location permission denied.
5. Location permission permanently denied.
6. Location services disabled.
7. GPS temporarily unavailable.
8. Poor GPS accuracy.
9. Stationary user.
10. Duplicate GPS coordinates.
11. Tiny GPS fluctuations.
12. Pause/resume.
13. App restart during tracking.
14. User deletes route.
15. User deletes route with tracking sessions.
16. Export cancellation.
17. Export failure.
18. No network connection.
19. Large number of route/tracking points.
20. Map initialization failure.

The app must not crash in these scenarios.

---

# 44. State Management

Recommended BLoCs/Cubits:

## RouteBloc

Responsible for:

- Load routes
- Create route
- Update route
- Delete route
- Load route details

## RouteCreationCubit

Responsible for:

- Selected map coordinate
- Route points
- Add point
- Undo
- Clear
- Save validation

## TrackingBloc

Responsible for:

- Start
- Pause
- Resume
- Stop
- Current tracking state
- Accepted GPS points
- Statistics

## LocationService / LocationCubit

Responsible for:

- Permission state
- Location service state
- Current GPS location
- GPS stream

## SettingsCubit

Responsible for:

- Load settings
- Change recording interval
- Persist settings

Keep responsibilities separated, but avoid creating unnecessary abstractions.

---

# 45. Important Business Logic Separation

The tracking business logic should be testable without Flutter widgets or Google Maps.

Create a dedicated component/use case for GPS point acceptance.

Conceptually:

```text
LocationUpdate
      ↓
LocationPointValidator
      ↓
accepted / rejected
```

It should determine:

- Is accuracy acceptable?
- Has enough time passed?
- Has the user moved enough?
- Should this point be persisted?

This logic must be unit-testable.

---

# 46. Unit Tests

Create unit tests for:

## Route

- Valid route
- Invalid route
- Minimum points
- Distance calculation

## GeoJSON

- Route → GeoJSON
- Correct longitude/latitude ordering
- JSON serialization

## GPS Filtering

Test:

```text
Same coordinate → rejected

Movement < 5m → rejected

Movement >= 5m → accepted

Accuracy > 50m → rejected

Accuracy <= 50m → eligible

Recording interval not elapsed → rejected
```

## Tracking

Test:

```text
start → tracking
pause → paused
resume → tracking
stop → completed
```

## Statistics

Test:

- Distance
- Duration
- Average speed

---

# 47. Data Integrity

Important:

Every accepted GPS point should be persisted before it is considered successfully recorded.

Avoid this pattern:

```text
GPS update
 ↓
Update UI
 ↓
Later save to DB
```

Prefer:

```text
GPS update
 ↓
Validate
 ↓
Persist
 ↓
Update application state/UI
```

This minimizes data loss.

---

# 48. Time Handling

Store timestamps in a consistent machine-readable format.

Prefer UTC internally:

```text
2026-09-16T08:45:23Z
```

Convert to local time only for display.

Use `DateTime` carefully and avoid mixing local and UTC values.

---

# 49. Distance Calculation

Use geographic distance calculation.

For planned route:

```text
Point 1 → Point 2 → Point 3
```

Calculate the sum of distances between consecutive points.

For actual tracking:

```text
GPS Point 1 → GPS Point 2 → GPS Point 3
```

Calculate the sum of distances between accepted tracking points.

Do not calculate distance from rejected points.

---

# 50. Average Speed

For a completed tracking session:

```text
averageSpeed = totalDistance / trackingDuration
```

Handle zero duration safely.

Do not produce `NaN` or infinity.

---

# 51. No Backend

Do not create:

- REST API
- Firebase database
- Authentication
- Cloud synchronization
- Server-side processing

The MVP is entirely local.

However, keep repository interfaces clean so a remote repository can be introduced later.

---

# 52. Future Extensibility

Do not implement these unless necessary:

- Backend sync
- Authentication
- Cloud storage
- Background tracking
- Offline map tiles
- Turn-by-turn navigation
- GPX
- Route deviation alerts
- Geofencing
- User accounts
- Route sharing

But design the domain layer so these can be added later.

---

# 53. Recommended Development Order

Implement in this order:

### Phase 1
Project setup:

- Flutter
- Material 3
- BLoC
- Clean Architecture
- Theme
- Navigation

### Phase 2
Local persistence:

- Route entity
- Tracking session entity
- Local database
- Settings storage

### Phase 3
Route creation:

- Google Maps
- Map tap selection
- Current location
- Route points
- Polyline
- Save route

### Phase 4
Route details:

- Route map
- Route information
- Planned distance

### Phase 5
GPS tracking:

- Permissions
- Location service
- GPS updates
- Interval filtering
- Accuracy filtering
- Movement filtering
- Persistence

### Phase 6
Tracking UI:

- Drive mode
- Follow location
- Pause
- Resume
- Stop
- Statistics

### Phase 7
JSON / GeoJSON:

- Serialization
- Viewer
- Export
- Share

### Phase 8
Settings:

- Location interval
- Persistence

### Phase 9
Testing:

- Unit tests
- Validation
- Edge cases

### Phase 10
Polish:

- Error handling
- Loading states
- Empty states
- UI refinement
- Performance

---

# 54. Claude Code Working Rules

When implementing this project:

1. First inspect the existing repository before changing files.
2. If this is an empty project, initialize the required Flutter structure.
3. Do not overwrite existing code blindly.
4. Keep changes modular.
5. Run formatting after implementation.
6. Run static analysis.
7. Run tests.
8. Fix compile/analyzer/test errors before considering a feature complete.
9. Do not leave placeholder implementations for required MVP features.
10. Do not use fake GPS data in the production implementation.
11. Do not hard-code Google Maps API keys.
12. Do not put business logic inside UI widgets.
13. Do not store tracking data only in memory.
14. Do not serialize the complete tracking dataset on every GPS update.
15. Keep the implementation simple enough to maintain.

---

# 55. Definition of Done

The MVP is considered complete when the following real-device flow works:

```text
Launch App
    ↓
Create Route
    ↓
Open Map
    ↓
Select Location 1
    ↓
Add Point
    ↓
Select Location 2
    ↓
Add Point
    ↓
Select Location 3
    ↓
Add Point
    ↓
Save Route
    ↓
Route appears on Home
    ↓
Open Route
    ↓
View planned route
    ↓
Start Tracking
    ↓
Grant location permission
    ↓
GPS starts
    ↓
Valid GPS points are stored locally
    ↓
Stationary/duplicate points are ignored
    ↓
Drive Mode displays actual GPS track
    ↓
Pause
    ↓
Resume
    ↓
Stop
    ↓
Tracking session saved
    ↓
Statistics displayed
    ↓
Open JSON
    ↓
View formatted JSON
    ↓
Export JSON / GeoJSON
    ↓
Share file
```

This entire flow must work without a backend.

---

# 56. Final Implementation Instruction

Act as a senior Flutter engineer.

Build the actual working MVP rather than only describing the architecture.

Before coding:

1. Inspect the repository.
2. Identify the Flutter/Dart version.
3. Check whether Flutter project files already exist.
4. Propose any necessary dependency choices briefly.
5. Then implement.

After implementation:

1. Run `dart format`.
2. Run `flutter analyze`.
3. Run available unit tests.
4. Fix errors.
5. Verify Android/iOS configuration.
6. Provide a concise summary of what was implemented.
7. Clearly list any configuration that requires developer action, especially Google Maps API keys.

Prioritize:

```text
Working functionality
Correct GPS handling
Data integrity
Offline persistence
Clean architecture
Maintainability
Performance
```

Do not over-engineer the MVP.
