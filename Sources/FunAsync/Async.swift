/// Async monad that wraps `() async -> T`.
public struct Async<T>
{
    public let run: () async -> T

    public init(run: @escaping () async -> T)
    {
        self.run = run
    }

    public init(_ value: T)
    {
        self.init { value }
    }

    public func map<U>(_ f: @escaping (T) -> U) -> Async<U>
    {
        .init {
            f(await run())
        }
    }

    public func zipWith<U>(_ u: Async<U>) -> Async<(T, U)>
    {
        .init {
            await (self.run(), u.run())
        }
    }

    public func flatMap<U>(_ f: @escaping (T) -> Async<U>) -> Async<U>
    {
        .init {
            await f(await run()).run()
        }
    }
}
