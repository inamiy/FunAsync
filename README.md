# ⏳ FunAsync

Collection of Swift 5.5 `async`/`await` utility functions.

- **Throw <-> Result conversion**
    - `asyncThrowsToAsyncResult`
    - `asyncResultToAsyncThrows`
- **More Concurrency helpers**
    - `asyncFirst` (`Promise.race`)
    - `asyncFirstSuccess` (`Promise.any`)
    - `asyncAll` (`Promise.all`)
    - `asyncOr` (sequential execution until first success)
    - `asyncStream` (from asyncs to `AsyncStream`)
    - `withRetry` (retries when failed)
    - `withTimeout` (racing with time)

## License

[MIT](LICENSE)
