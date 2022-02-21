# Using with Hotwire

AnyCable is fully compatible with [Hotwire][] applications without any additional configuration. See [Getting started guide](./getting_started.md).

## RPC-less setup

> 📖 See also [JWT identification and “hot streams”](https://anycable.io/blog/jwt-identification-and-hot-streams/).

AnyCable-Go provides a feature called [signed streams](../anycable-go/signed_streams.md), which implements the require `turbo-rails` Action Cable functionality right in the WebSocket server. That means, subscribing to Turbo Streams doesn't require calling a gRPC Rails server.

In case you're using only Turbo Streams and not relying on _pure_ Action Cable, you can simplify your AnyCable configuration (infrastructure, deployment) by switching to signed streams and [JWT authentication](../anycable-go/jwt_identification.md).

The default flow with AnyCable RPC looks like this:

```mermaid
sequenceDiagram
    participant Rails
    participant AnyCableRPC
    participant AnyCableGo
    participant Client
    autonumber
    Rails-->>Client: action_cable_meta_tag
        Client->>AnyCableGo: HTTP Connect

    activate AnyCableGo
    AnyCableGo->>AnyCableRPC: gRPC Connect
        activate AnyCableRPC
        note left of AnyCableRPC: ApplicationCable::Connection#35;connect
        AnyCableRPC->>AnyCableGo: Status OK
        deactivate AnyCableRPC
        AnyCableGo->>Client: Welcome
    deactivate AnyCableGo

    Rails-->>Client: turbo_stream_from signed_stream_id
        Client->>AnyCableGo: Subscribe to signed_stream_id

    activate AnyCableGo
    AnyCableGo-->>AnyCableRPC: gRPC Command subscribe
        activate AnyCableRPC
        note left of AnyCableRPC: Turbo::StreamChannel#35;subscribe
        AnyCableRPC->>AnyCableGo: Status OK
        deactivate AnyCableRPC
        AnyCableGo->>Client: Subscription Confirmation
    deactivate AnyCableGo

    loop
        Rails--)AnyCableGo: ActionCable.server.broadcast
            AnyCableGo->>Client: Deliver <turbo-stream>
    end
```

Compare it to the RPC-less configuration with the aforementioned features below:

```mermaid
sequenceDiagram
    participant Rails
    participant AnyCableGo
    participant Client
    autonumber
    Rails-->>Client: action_cable_meta_tag_with_jwt(user: current_user)
        Client->>AnyCableGo: HTTP Connect

    activate AnyCableGo
    note left of AnyCableGo: Verify JWT and store identifiers
        AnyCableGo->>Client: Welcome
    deactivate AnyCableGo

    Rails-->>Client: turbo_stream_from signed_stream_id
        Client->>AnyCableGo: Subscribe to signed_stream_id

    activate AnyCableGo
    note left of AnyCableGo: Verify Signed Stream ID and Subscribe
        AnyCableGo->>Client: Subscription Confirmation
    deactivate AnyCableGo

    loop
        Rails--)AnyCableGo: ActionCable.server.broadcast
            AnyCableGo->>Client: Deliver <turbo-stream>
    end
```

> 🎥 Check out this AnyCasts screencast as a video guide on setting up Hotwire with AnyCable in the RPC-less way: [Exploring Rails 7, Hotwire and AnyCable speedy streams](https://anycable.io/blog/anycasts-rails-7-hotwire-and-anycable/).

### Step-by-step guide on going RPC-less

- Install and configure [anycable-rails-jwt][] gem:

```yml
# anycable.yml
production:
  jwt_id_key: "some-secret-key"
```

- Configure Turbo Streams verifier key:

```ruby
# config/environments/production.rb
config.turbo.signed_stream_verifier_key = "s3cЯeT"
```

- Disable Disconnect calls and enable JWT identification and signed streams in AnyCable-Go:

```sh
ANYCABLE_JWT_ID_KEY=some-secret-key \
ANYCABLE_TURBO_RAILS_KEY=s3cЯeT \
ANYCABLE_DISABLE_DISCONNECT=true \
anycable-go

# or via cli args
anycable-go --jwt_id_key=some-secret-key --turbo_rails_key=s3cЯeT --disable_disconnect
```

**NOTE:** Disabling `Disconnect` calls is safe unless you have some custom logic in the `ApplicationCable::Connection#disconnect` method. Otherwise, you still need to run the RPC server.

[Hotwire]: https://hotwired.dev
[anycable-rails-jwt]: https://github.com/anycable/anycable-rails-jwt
