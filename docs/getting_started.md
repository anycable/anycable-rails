# AnyCable on Rails

AnyCable can be used as a drop-in replacement for Action Cable in Rails applications. It supports most Action Cable features (see [Compatibility](./compatibility.md) for more) and can be used with any Action Cable client. Moreover, AnyCable brings additional power-ups for your real-time features, such as [streams history support](../guides/reliable_streams.md) and API extensions (see [below](#action-cable-extensions)).

> See also the [demo](https://github.com/anycable/anycable_rails_demo/pull/2) of migrating from Action Cable to AnyCable.

## Requirements

- Ruby >= 2.7
- Rails >= 6.0

See also requirements for [broadcast adapters](../ruby/broadcast_adapters.md) (You can start with HTTP to avoid additional dependencies).

## Installation

Add AnyCable Rails gem to your Gemfile:

```ruby
# If you plan to use gRPC
gem "anycable-rails", "~> 1.5"

# If you plan to use HTTP RPC or no RPC at all
gem "anycable-rails-core", "~> 1.5"
```

Read more about different RPC modes [here](../anycable-go/rpc.md).

Then, run the interactive configuration wizard via Rails generators:

```sh
bin/rails g anycable:setup
```

The command above asks you a few questions to configure AnyCable for your application. Want more control? Check out the [manual setup section](#manual-setup) below.

## Configuration

AnyCable Rails uses [Anyway Config][] for configuration. Thus, you can store configuration parameters whenever you want: YAML files, credentials, environment variables, whatever.

We recommend keeping non-sensitive and _stable_ parameters in `config/anycable.yml`, e.g., broadcast adapter, default JWT TTL, etc.

For secrets (`secret`, `broadcast_key`, etc.), we recommend using Rails credentials.

The most important configuration settings are:

- **secret**: a common secret used to secure AnyCable features (signed streams, JWT, etc.). Make sure the value is the same for your Rails application and AnyCable server.

- **broadcast_adapter**: defines how to deliver broadcast messages from the Rails application to AnyCable server (so it can transmit them to connected clients). See [broadcasting docs](../ruby/broadast_adapters.md) for available options and their configuration.

See AnyCable Ruby [configuration](../ruby/configuration.md) for more information.

### Forgery protection

AnyCable respects [Action Cable configuration](https://guides.rubyonrails.org/action_cable_overview.html#allowed-request-origins) regarding forgery protection if and only if `ORIGIN` header is proxied by AnyCable server, i.e.:

```sh
anycable-go --headers=cookie,origin --port=8080
```

However, we recommend performing the origin check at the AnyCable server side (via the `--allowed_origins` option). See [AnyCable configuration](../anycable-go/configuration.md).

### Embedded gRPC server

It is possible to run AnyCable gRPC server within another Ruby process (Rails server or tests runner). We recommend using this option in development and test environments only or in single-process production environments.

To automatically start a gRPC server every time you run `rails s`, add `embedded: true` to your configuration. For example:

```yml
# config/anycable.yml
development:
  embedded: true
```

**NOTE:** Make sure you have `Rails.application.load_server` in your `config.ru`. The feature is available since Rails 6.1.

## Manual setup

### Development

First, activate AnyCable in your Rails application by specifying it as an adapter for Action Cable:

```yml
# config/cable.yml
development:
  adapter: any_cable
  # ...
```

Install [AnyCable server](#server-installation) and specify its URL in the configuration:

```ruby
# config/environments/development.rb

# For development, it's likely the localhost
config.action_cable.url = "ws://localhost:8080/cable"
```

Finally, add the following commands to your `Procfile.dev` file\*:

```sh
web: bin/rails s
# ...
ws: anycable-go
# When using gRPC
rpc: bundle exec anycable
```

Now, run your application via your process manager (or `bin/dev`, if any). You are AnyCable-ready!

\* If you don't have a process manager yet, we recommend using [Overmind][]. [Foreman][] works, too.

**IMPORTANT**: Despite AnyCable providing multiple RPC modes, we recommend having similar development and production setups. Thus, if you use gRPC in production, use it in development, too.

### Production

> The quickest way to get AnyCable server for production usage is to use our managed (and free) solution: [plus.anycable.io](https://plus.anycable.io)

Whenever you're ready to push youre AnyCable-backed Rails application to production (or staging), make sure your application is configured the right way:

- Configure Action Cable adapter for production:

  ```yml
  # config/cable.yml
  production:
    adapter: any_cable
    # ...
  ```

- Update Action Cable configuration to point clients to connect to AnyCable server

  ```ruby
  # config/environments/production.rb
  config.action_cable.url = ENV.fetch("ANYCABLE_WEBSOCKET_URL")
  ```

  **IMPORTANT:** The URL configuration is used by the `#action_cable_meta_tag` helper. Make sure you have it in your HTML layout.

- When using gRPC server, make sure you have a corresponding new process added to your deployment.

Check out our [deployment guides](../deployment) to learn more about your deployment method and AnyCable.

## Server installation

For your convenience, we provide a binstub (`bin/anycable-go`) which automatically downloads an AnyCable server binary (and caches it) and launches it. Run the following command to add it to your project:

```sh
$ bundle exec rails g anycable:bin

...
```

You can also install AnyCable server yourself using one of the [multiple ways](../anycable-go/getting_started.md#installation).

## Action Cable extensions

### Broadcast to others

AnyCable provides a functionality to deliver broadcasts to all clients except from the one initiated the action (e.g., when you need to broadcast a message to all users in a chat room except the one who sent the message).

> **NOTE:** This feature is not available in Action Cable. It relies on [Action Cable protocol extensions](../misc/action_cable_protocol.md) currently only supported by AnyCable.

To do so, you need to obtain a unique socket identifier. For example, using [AnyCable JS client](https://github.com/anycable/anycable-client), you can access it via the `cable.sessionId` property.

Then, you must attach this identifier to HTTP request as a `X-Socket-ID` header value. AnyCable Rails uses this value to populate the `AnyCable::Rails.current_socket_id` value. If this value is set, you can implement broadcasting to other using one of the following methods:

- Calling `ActionCable.server.broadcast stream, data, to_others: true`
- Calling `MyChannel.broadcast_to stream, data, to_others: true`

Finally, if you perform broadcasts indirectly, you can wrap the code with `AnyCable::Rails.broadcasting_to_others` to enable this feature. For example, when using Turbo Streams:

```ruby
AnyCable::Rails.broadcasting_to_others do
  Turbo::StreamsChannel.broadcast_remove_to workspace, target: item
end
```

You can also pass socket ID explicitly (if obtained from another source):

```ruby
AnyCable::Rails.broadcasting_to_others(socket_id: my_socket_id) do
 # ...
end

# or
ActionCable.server.broadcast stream, data, exclude_socket: my_socket_id
```

**IMPORTANT:** AnyCable Rails automatically pass the current socket ID to Active Job, so you can use `broadcast ..., to_others: true` in your background jobs without any additional configuration.

### Batching broadcasts automatically

AnyCable supports publishing [broadcast messages in batches](../ruby/broadcast_adapters.md#batching) (to reduce the number of round-trips and ensure delivery order). You can enable automatic batching of broadcasts by setting `ANYCABLE_BROADCAST_BATCHING=true` (or `broadcast_batching: true` in the config file).

Auto-batching uses [Rails executor](https://guides.rubyonrails.org/threading_and_code_execution.html#executor) under the hood, so broadcasts are aggregated within Rails _units of work_, such as HTTP requests, background jobs, etc.

### Testing with AnyCable

If you'd like to run AnyCable gRPC server in tests (for example, in system tests), we recommend to start it manually only when necessary (i.e., when dependent tests are executed) and use the embedded mode.

You can also run AnyCable server automatically when starting a gRPC server.

That's how we do it with RSpec:

```ruby
# spec/support/anycable_setup.rb
RSpec.configure do |config|
  cli = nil

  config.before(:suite) do
    examples = RSpec.world.filtered_examples.values.flatten
    has_no_system_tests = examples.none? { |example| example.metadata[:type] == :system }

    # Only start RPC server if system tests are included into the run
    next if has_no_system_tests

    require "anycable/cli"

    $stdout.puts "\n⚡️  Starting AnyCable RPC server...\n"
    AnyCable::CLI.embed!(%w[--server-command=bin/anycable-go])
  end
end
```

To use `:test` Action Cable adapter along with AnyCable, you can extend it in the configuration:

```rb
# config/environments/test.rb
Rails.application.configure do
  config.after_initialize do
    # Don't forget to configure URL
    config.action_cable.url = ActionCable.server.config.url = ENV.fetch("CABLE_URL", "ws://localhost:8080/cable")

    # Make test adapter AnyCable-compatible
    AnyCable::Rails.extend_adapter!(ActionCable.server.pubsub)
  end

  # ...
end
```

## Gradually migrating from Action Cable

In case switching from Action Cable to AnyCable requires updating the WebSocket url (e.g., when you have no control over a load balancer or ingress, so you can't just switch `/cable` traffic to a different service), you might want to pay additional attention to the migration.

First, you need to continue using your current pubsub adapter for Action Cable (say, `redis`). Clients could continue using the Rails endpoint (`ws://<web>/cable`) as well as connect via the AnyCable one (`ws://<anycable-go>/cable`).

To publish updates to both _cables_, we need to use the _dual broadcast_ strategy. For that, you need to extend your pubsub adapter to send data to AnyCable:

```ruby
# config/initializers/anycable.rb
AnyCable::Rails.extend_adapter!(ActionCable.server.pubsub)
```

**NOTE:** If you use `graphql-anycable`, things become more complicated. You will need to schemas with different subscriptions providers and a similar dual adapter to support both _cables_.

[Overmind]: https://github.com/DarthSim/overmind
[Foreman]: https://github.com/ddollar/foreman
[Anyway Config]: https://github.com/palkan/anyway_config
