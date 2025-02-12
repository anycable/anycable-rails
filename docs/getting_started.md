# AnyCable on Rails

AnyCable can be used as a drop-in replacement for Action Cable in Rails applications. It supports most Action Cable features (see [Compatibility](./compatibility.md) for more) and can be used with any Action Cable client. Moreover, AnyCable brings additional power-ups for your real-time features, such as [streams history support](../guides/reliable_streams.md) and [API extensions](./extensions.md).

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

### Prerequisites

Make sure you have `require "action_cable/engine"` or `require "rails/all"` in your `config/application.rb` (AnyCable relies Action Cable abstractions).

### Development

First, activate AnyCable in your Rails application by specifying it as an adapter for Action Cable:

```yml
# config/cable.yml
development:
  adapter: any_cable
  # ...
```

Then, create `config/anycable.yml` with basic AnyCable configuration:

```yml
# config/anycable.yml
development:
  broadcast_adapter: http
  websocket_url: ws://localhost:8080/cable
```

Install [AnyCable server](#server-installation) and add the following commands to your `Procfile.dev` file\*:

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

Whenever you're ready to push your AnyCable-backed Rails application to production (or staging), make sure your application is configured the right way:

- Configure Action Cable adapter for production:

  ```yml
  # config/cable.yml
  production:
    adapter: any_cable
    # ...
  ```

- Provide AnyCable WebSocket URL via the `ANYCABLE_WEBSOCKET_URL` environment variable.

  Alternatively, you can use Rails credentials or YAML configuration.

  **IMPORTANT:** The URL configuration is used by the `#action_cable_meta_tag` helper. Make sure you have it in your HTML layout.

- Make sure you configured secrets obtained from your AnyCable server (`secret`, `broadcast_key`, etc.)

- When using gRPC server, make sure you have a corresponding new process added to your deployment.

Check out our [deployment guides](../deployment) to learn more about your deployment methods and AnyCable.

## Server installation

For your convenience, we provide a binstub (`bin/anycable-go`) which automatically downloads an AnyCable server binary (and caches it) and launches it. Run the following command to add it to your project:

```sh
$ bundle exec rails g anycable:bin

...
```

You can also install AnyCable server yourself using one of the [multiple ways](../anycable-go/getting_started.md#installation).

## Testing with AnyCable

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
    # Don't forget to configure URL in your anycable.yml or via ANYCABLE_WEBSOCKET_URL
    config.action_cable.url = ActionCable.server.config.url = AnyCable.config.websocket_url

    # Make test adapter AnyCable-compatible
    AnyCable::Rails.extend_adapter!(ActionCable.server.pubsub)
  end

  # ...
end
```

## Gradually migrating from Action Cable

It's possible to run AnyCable along with Action Cable, so you can still serve legacy connections (or perform gradual roll-out, A/B testing, etc.). A common use-case is switching from Action Cable to AnyCable while updating the WebSocket URL (e.g., when you have no control over a load balancer or ingress, so you can't just switch `/cable` traffic to a different service).

To achieve a smooth migration, you need to accomplish the following steps:

- Continue using your current pub/sub adapter for Action Cable (say, `redis`) but extend it with AnyCable broadcasting capabilities by adding the following code:

  ```ruby
  # config/initializers/anycable.rb
  AnyCable::Rails.extend_adapter!(ActionCable.server.pubsub) unless AnyCable::Rails.enabled?
  ```

- You can also add AnyCable JWT support to Action Cable. See [authentication docs](./authentication.md#jwt-authentication).

That's it! Now you can serve Action Cable clients via both `ws://<rails>/cable` and `ws://<anycable>/cable`, and they should be able to communicate with each other.

**NOTE:** If you use `graphql-anycable`, things become more complicated. You will need to schemas with different subscriptions providers and a similar dual adapter to support both _cables_.

[Overmind]: https://github.com/DarthSim/overmind
[Foreman]: https://github.com/ddollar/foreman
[Anyway Config]: https://github.com/palkan/anyway_config
