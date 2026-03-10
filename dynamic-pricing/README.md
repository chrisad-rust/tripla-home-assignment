<div align="center">
   <img src="/img/logo.svg?raw=true" width=600 style="background-color:white;">
</div>

# Solution to the “Dynamic Pricing Proxy” Take-Home Assignment

For the challenge description, please see the instructions [here](/dynamic-pricing/INSTRUCTION_README.md).

This document describes my approach, design decisions, and the reasoning behind the implementation of the Dynamic Pricing Proxy.

Whenever possible, I try to follow standard Rails conventions and concepts in order to keep the implementation maintainable and easy to understand.


## Requirements

The solution must compensate for the slow performance of the external rate API while ensuring that the price rates are cached for no longer than five minutes. Incoming requests must be validated to ensure correct parameters and valid rate lifetimes. The service should return results as quickly as possible and provide clear error responses if a request cannot be processed.


## Architecture Overview

To avoid the latency of the external rate API during request processing, the system caches all possible rate data. These price rates are refreshed periodically in the background and then served directly from the data store.

The design separates the system into three responsibilities: 
- fetching price rates from the external API, 
- storing the retrieved data, 
- and serving requests using the cached data. 

This approach ensures that request latency is not affected by the performance of the upstream service.


## Background Rate Fetching

Since the external API is sometimes relatively slow, price rates are retrieved asynchronously using a background job. Because the background process cannot predict which rates will be requested by clients, it retrieves the full set of available rates and updates the storage.

In Rails, asynchronous tasks are typically implemented using **ActiveJob**, which provides a unified interface for background processing frameworks.

The update job is scheduled using a time-based trigger rather than being initiated by user requests. This decision was made because the expected request volume is unknown and the cache freshness requirement specifies a maximum age of five minutes for stored price rates.

For scheduling the background task I chose **sidekiq-cron**. This scheduler integrates well with **Sidekiq** and **ActiveJob** and provides reliable time-based execution of background jobs. The update job is currently scheduled to run once per minute. Running the job at this interval ensures that cached price rates remain within the allowed freshness window even if an individual update attempt fails.


## Rate Storage and Caching

Exchange rates are stored using **ActiveRecord** with the existing SQL database backend. This approach integrates naturally with Rails and requires minimal additional infrastructure. Persisting the data in the database also allows the system to be extended later to support historical rate tracking or auditing.

Other caching solutions such as Redis could also be considered. Redis would provide faster in-memory access and could be beneficial for systems with very high request volumes. In this implementation, however, a SQL-based solution was chosen because it simplifies persistence and fits well with the existing Rails data model.


## Data Validation

Incoming requests are validated at the API boundary. Parameters such as hotel, room, and period are checked before processing the request. The system also verifies that a valid rate exists within the allowed freshness window.

The freshness check is based on the timestamp of the most recent successful rate update job. Because all rates are fetched together during the update process, they share the same validity window.

## Fast Response Strategy

To ensure fast responses, the API endpoint retrieves price rates using a single optimized database query that selects the most recent valid rate within the allowed time range.

Because the price rates are already stored, the service does not need to call the external API while processing user requests. This removes the dependency on the upstream API latency and allows responses to be returned quickly and consistently.

## Error Handling

Failures that occur during the background update process are recorded and stored together with the corresponding update job. This information can be used to diagnose problems with the external rate API.

If no valid exchange rate is available when a request is processed, the service returns an appropriate error response. The next scheduled update job will attempt to refresh the rates again.

## Trade-offs

The chosen design favors simplicity and reliability over maximum efficiency. Fetching all price rates periodically guarantees that the required data is available, but it may result in unnecessary API calls if only a small subset of rates is actually requested.

Using the SQL database for caching simplifies integration with Rails and allows the data to be persisted. However, it may not perform as well as a dedicated in-memory cache under very high load.

The time-based refresh strategy ensures predictable cache freshness, although it may retrieve data that is not immediately used.

## Implementation Steps

The implementation follows a test-driven approach in which each component is introduced by first defining the expected behavior in tests and then implementing the corresponding functionality.

- [x] Define database models for `PriceRate` and `PriceRateUpdateInfo`
- [ ] Write tests that verify the persistence and retrieval of rate and update job data
- [ ] Implement the persistence logic required for storing and querying price rates
- [ ] Write tests for the background update job that validate correct interaction with the rate API and proper storage of results
- [ ] Implement the background update job
- [ ] Configure the scheduler to run the update job every minute
- [ ] Write tests for the rate query service covering valid responses, cache freshness checks, and error cases
- [ ] Implement the rate query service and request validation
- [ ] Ensure all components are covered by automated tests