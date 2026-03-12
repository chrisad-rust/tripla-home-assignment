<div align="center">
   <img src="/img/logo.svg?raw=true" width=600 style="background-color:white;">
</div>

# Dynamic Pricing Proxy – Solution

This repository contains my solution for the Dynamic Pricing Proxy take-home assignment.

For the challenge description, please see the instructions [here](/dynamic-pricing/INSTRUCTION_README.md).

The goal of this service is to provide fast access to dynamic price rates while compensating for the potentially slow response times of an external rate API.

To achieve this, the system periodically fetches rate data from the upstream service and caches it. 
Client requests are then served directly from the cached data, avoiding the latency of the external API.

The implementation follows standard conventions of Ruby on Rails to keep the solution simple and maintainable.

## Requirements

The system is designed with the following goals:
- Fast response times independent of upstream API latency
- Guarantees cache freshness (<= 5 minutes)
- Stable responses even if the upstream service fails
- Clear failure behavior

## Assumptions

The implementation assumes:
- the number of rate combinations is reasonably small and can be fully refreshed periodically
- the external API allows periodic full retrieval
- the update job completes within the scheduling interval
- the availability of the rooms is given in a 5 minute time window 

## Architecture Overview

Calling the external API during request processing would introduce unpredictable latency and potential request failures.
By periodically synchronizing rate data in the background, request handling becomes deterministic and independent of the upstream API performance.

The design separates the system into three responsibilities: 
1. Fetching price rates from the external API
2. Storing the retrieved rates
3. Serving client requests using cached data

### Data Flow

```
    Rate API
        │
        ▼
Background Update Job
        │
        ▼
Database (cached rates)
        │
        ▼
   Pricing proxy
        │
        ▼
      Client
```

### System Components

The application consists of:

- Rails API service
- Sidekiq worker
- Redis (job queue)
- SQL database (rate storage)

This approach ensures that request latency is not affected by the performance of the upstream service.

## Background Rate Fetching

Because the external API may respond slowly, rate data is fetched asynchronously using a background job.

The background job retrieves the complete set of available price rates and stores them in the database. This ensures that the service can answer requests immediately using cached data.

The update job runs periodically using a cron-style scheduler.

### Scheduling

The system uses:

- **ActiveJob** for background job abstraction
- **Sidekiq** for background processing
- **sidekiq-cron** for scheduled execution

The update job runs once per minute. This interval ensures that cached rates remain within the five-minute freshness requirement even if an update attempt temporarily fails.

### Concurrency Considerations

Rates retrieved from the external API are written to the database in batch inserts.

Existing rows are never updated. This approach provides two benefits:
- queries always operate on a consistent snapshot
- race conditions between reads and updates are avoided

In the unlikely event that update jobs overlap, additional batches may be inserted.
Since queries always select the most recent valid data, this does not affect correctness.

## Rate Storage and Caching

Price rates are stored using the existing SQL database through the standard Rails persistence layer.

Benefits of this approach include:
- seamless integration with the Rails application
- persistent storage of rate data
- simple schema management
- potential extension to historical tracking

An alternative approach would be using an in-memory cache such as Redis. While Redis could provide faster access under heavy load, a SQL-based solution was chosen for simplicity and easier integration with the Rails data model.

### Data Model

Rates are stored in two tables:

- **PriceRateUpdateInfo**
  - metadata about each update job execution
  - includes success state, error message and execution timestamp

- **PriceRate**
  - individual rate entries
  - contains lookup hash, rate value and reference to the update batch

This structure allows grouping rates by update execution and simplifies cleanup of outdated data.

## Data Validation

Incoming requests are validated at the API boundary.

The following parameters are checked:
- hotel identifier (FloatingPointResort, GitawayHotel, RecursionRetreat)
- room type (SingletonRoom, BooleanTwin, RestfulKing)
- booking period (Summer, Autumn, Winter, Spring)
- existence of a valid rate

Additionally, the system verifies that the returned rate was fetched within the allowed freshness window of five minutes.
Because the update job fetches all rates at once, all rates share the same validity window.

## Fast Response Strategy

To ensure minimal latency for client requests:
- the service never calls the external API during request processing
- cached data is queried directly from the database

Each request retrieves the most recent valid rate using a single optimized query.
This approach guarantees fast and consistent response times regardless of upstream API performance.

## Error Handling

Failures during the background update process are recorded and stored together with update metadata. This allows issues with the external API to be diagnosed.

When processing client requests:
- if a valid rate exists within the allowed freshness window, it is returned
- if no valid rate is available, the service returns an error response

This ensures that clients never receive stale data that violates the freshness requirement.

## Data Cleanup

Since rate updates are stored as batches, older data must be removed periodically.
A cleanup job deletes all records older than five minutes to ensure that the database does not grow indefinitely.
This job runs periodically and keeps the dataset limited to the currently valid rate window.

## Trade-offs

The chosen design favors simplicity and reliability over maximum efficiency.

### Periodic full refresh

Fetching all rates periodically guarantees that required data is available but may result in unnecessary API calls if only a subset of rates is requested.

### SQL-based caching

Using the SQL database simplifies integration with Rails and allows persistent storage, but may not match the performance of an in-memory cache under extremely high load.

### Time-based refresh strategy

Running the update job periodically ensures predictable cache freshness, even if the external API temporarily fails.

## Possible Future Improvements

- Use Redis for high-performance caching in high-traffic scenarios.
- Add monitoring for background job failures, so that issues with the upstream API can be detected quickly.
- Introduce distributed locking to avoid overlapping update jobs.
- Extend the system to support historical rate tracking.
- Request data from Rate API in batches to reduce network payload size.

## Setup

```bash
# --- 1. Migrate database if necessary ---
# Run database migrations in a temporary container.
# This avoids race conditions when multiple containers start simultaneously.
docker compose run --rm interview-dev ./bin/rails db:migrate

# --- 2. Build & Run The Main Application ---
# Build and run the Docker compose
docker compose up -d --build interview-dev

# --- 3. Test The Endpoint ---
# Send a sample request to your running service
curl 'http://localhost:3000/api/v1/pricing?period=Summer&hotel=FloatingPointResort&room=SingletonRoom'

# --- 3. Run Tests ---
# Run the full test suite
docker compose exec interview-dev ./bin/rails test

# Run a specific test file
docker compose exec interview-dev ./bin/rails test test/controllers/pricing_controller_test.rb

# Run a specific test by name
docker compose exec interview-dev ./bin/rails test test/controllers/pricing_controller_test.rb -n test_should_get_pricing_with_all_parameters
```

## Usage

### Request

GET /api/v1/pricing

Parameters:
- period (required)
- hotel (required)
- room (required)

```bash
GET http://localhost:3000/api/v1/pricing?period=Summer&hotel=FloatingPointResort&room=SingletonRoom
```
### Successful Response
```json
{
  "rate": 29100
}
```
### Error Response
```json
{
  "error": "An unexpected internal error occurred"
}
```
Errors may occur when:
- parameters are invalid
- no cached rate exists
- the cached data is older than five minutes

## Remarks
- I spend around 20 hours on this project.
- I used the ChatGPT AI as a review tool to challenge and polish my work.