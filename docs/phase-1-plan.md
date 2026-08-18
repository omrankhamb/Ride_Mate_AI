# Phase 1 Plan

## Objective

Build the first working foundation of RideMate AI before 21 August.

## Included

- Rider signup
- Rider login
- Driver signup
- Driver login
- Role-based dashboard
- Driver online/offline control
- Rider ride request form
- Demo ride matching when a driver is online
- OTP display and ride status flow

## Not Included

- KYC
- Admin dashboard
- Payment gateway
- Real maps API
- Machine learning model
- PostgreSQL runtime connection
- Live production GPS

## Demo Flow

1. Create a driver account.
2. Login as driver.
3. Set driver online.
4. Open another browser tab.
5. Create a rider account.
6. Login as rider.
7. Enter pickup and destination.
8. Request a shared auto.
9. Driver sees the request.
10. Driver accepts, enters OTP, starts, and completes the ride.

## Phase 2 Upgrade

- Replace mock map with Google Maps or Mapbox.
- Add real latitude and longitude.
- Add WebSocket live driver location.
- Add nearby driver matching by distance.
- Add co-rider matching rules.
