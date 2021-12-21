# Getting Started with AnyCable on Rails

AnyCable initially was designed for Rails applications only.

> See also the [demo](https://github.com/anycable/anycable_rails_demo/pull/2) of migrating from Action Cable to AnyCable.

## Requirements

- Ruby >= 2.6
- Rails >= 6.0
- Redis (when using Redis [broadcast adapter](../ruby/broadcast_adapters.md))

## Installation

Add `anycable-rails` gem to your Gemfile:

```ruby
gem "anycable-rails", "~> 1.1"

# when using Redis broadcast adapter
gem "redis", ">= 4.0"
```

(and don't forget to run `bundle install`).

Then, run the interactive configuration wizard via Rails generators:

```sh
bundle exec rails g anycable:setup
```

## Configuration

Next, update your Action Cable configuration:

```yml
# config/cable.yml
production:
  # Set adapter to any_cable to activate AnyCable
  adapter: any_cable
```

Install [WebSocket server](#server-installation) and specify its URL in the configuration:

```ruby
# For development it's likely the localhost

# config/environments/development.rb
config.action_cable.url = "ws://localhost:8080/cable"

# For production it's likely to have a sub-domain and secure connection

# config/environments/production.rb
config.action_cable.url = "wss://ws.example.com/cable"
```

Now you can start AnyCable RPC server for your application:

```sh
$ bundle exec anycable
#> Starting AnyCable gRPC server (pid: 48111)
#> Serving Rails application from ./config/environment.rb

# don't forget to provide Rails env in production
$ RAILS_ENV=production bundle exec anycable
```

**NOTE**: you don't need to specify `-r` option (see [CLI docs](../ruby/cli.md)), your application would be loaded from `config/environment.rb`.

And, finally, run AnyCable WebSocket server, e.g. [anycable-go](../anycable-go/getting_started.md):

```sh
$ anycable-go --host=localhost --port=8080

INFO 2019-08-07T16:37:46.387Z context=main Starting AnyCable v0.6.2-13-gd421927 (with mruby 1.2.0 (2015-11-17)) (pid: 1362)
INFO 2019-08-07T16:37:46.387Z context=main Handle WebSocket connections at /cable
INFO 2019-08-07T16:37:46.388Z context=http Starting HTTP server at localhost:8080
```

You can store AnyCable-specific configuration in YAML file (similar to Action Cable one):

```yml
# config/anycable.yml
development:
  redis_url: redis://localhost:6379/1
production:
  redis_url: redis://my.redis.io:6379/1
```

Or you can use the environment variables (or anything else supported by [anyway_config](https://github.com/palkan/anyway_config)).

### Server installation

You can install AnyCable-Go server using one of the [multiple ways](../anycable-go/getting_started.md#installation).

For your convenience, we have a generator task which could be used to download a binary from GitHub released for your platform:

```sh
$ bundle exec rails anycable:download

run  curl -L https://github.com/anycable/anycable-go/releases/download/...
```

You can specify the target bin path (`--bin-path`) or AnyCable-Go version (`--version`).

**NOTE:** This task uses cURL under the hood, so it must be available.

### Access logs

Rails integration extends the base [configuration](../ruby/configuration.md) by adding a special parameter–`access_logs_disabled`.

This parameter turn on/off access logging (`Started <request data>` / `Finished <request data>`) (disabled by default).

You can configure it via env var (`ANYCABLE_ACCESS_LOGS_DISABLED=0` to enable) or config file:

```yml
# config/anycable.yml
production:
  access_logs_disabled: false
```

### Forgery protection

AnyCable respects [Action Cable configuration](https://guides.rubyonrails.org/action_cable_overview.html#allowed-request-origins) regarding forgery protection if and only if `ORIGIN` header is proxied by WebSocket server:

```sh
# with anycable-go
$ anycable-go --headers=cookie,origin --port=8080
```

## Logging

AnyCable uses `Rails.logger` as `AnyCable.logger` by default, thus setting log level for AnyCable (e.g. `ANYCABLE_LOG_LEVEL=debug`) won't work, you should configure Rails logger instead, e.g.:

```ruby
# in Rails configuration
config.logger = Logger.new($stdout)
config.log_level = :debug

# or
Rails.logger.level = :debug if AnyCable.config.debug?
```

Read more about [logging](../ruby/logging.md).

## Development and test

AnyCable is [compatible](compatibility.md) with the original Action Cable implementation; thus you can continue using Action Cable for development and tests.

Compatibility could be enforced by [runtime checks](compatibility.md#runtime-checks) or [static checks](compatibility.md#rubocop-cops) (via [RuboCop](https://github.com/rubocop-hq/rubocop)).

Use process manager (e.g. [Hivemind](https://github.com/DarthSim/hivemind) or [Overmind](https://github.com/DarthSim/overmind)) to run AnyCable processes in development with the following `Procfile`:

```procfile
web: bundle exec rails s
rpc: bundle exec anycable
ws:  anycable-go
```

### Embedded mode

It is also possible to run RPC server within another Ruby process (Rails server or tests runner). We recommend using this option in development and test environments.

When using Rails 6.1, you can automatically start an RPC server every time you run `rails s` by specifying the following configuration parameter:

```yml
# config/anycable.yml
development:
  embedded: true
```

**NOTE:** Make sure you have `Rails.application.load_server` in your `config.ru`.

### Testing with AnyCable

If you'd like to run AnyCable RPC server in tests (for example, in system tests), we recommend to start it manually only when necessary (i.e., when dependent tests are executed) and use the embedded mode. That's how we do it with RSpec:

```ruby
# spec/support/anycable_setup.rb
RSpec.configure do |config|
  # Only start RPC server if system tests are included into the run
  next if config.filter.opposite.rules[:type] == "system" || config.exclude_pattern.match?(%r{spec/system})

  require "anycable/cli"
  AnyCable::CLI.embed!

  # Make sure AnyCable pubsub adapter is used in system tests (and test adapter otherwise, so we can run unit tests)
  config.before(:each, type: :system) do
    next if ActionCable.server.pubsub.is_a?(ActionCable::SubscriptionAdapter::AnyCable)

    @__was_pubsub_adapter__ = ActionCable.server.pubsub

    adapter = ActionCable::SubscriptionAdapter::AnyCable.new(ActionCable.server)
    ActionCable.server.instance_variable_set(:@pubsub, adapter)
  end

  config.after(:each, type: :system) do
    next unless instance_variable_defined?(:@__was_pubsub_adapter__)
    ActionCable.server.instance_variable_set(:@pubsub, @__was_pubsub_adapter__)
  end
end
```

## Gradually migration from Action Cable

In case switching from Action Cable to AnyCable requires updating the WebSocket url (e.g., when you have no control over a load balancer or ingress, so you can't just switch `/cable` traffic to a different service), you might want to pay additional attention to the migration.

One option is to use a _dual broadcast_ strategy while using Action Cable within web instances. For that, you need a custom pubsub adapter to send messages to both Action Cable and AnyCable. Here is an example:

```ruby
require "anycable"
require "action_cable/subscription_adapter/redis"

module ActionCable
  module SubscriptionAdapter
    class AnyRedisCable < Redis
      def broadcast(channel, payload)
        super
        ::AnyCable.broadcast(channel, payload)
      end
    end
  end
end
```

Then, in `cable.yml` set `adapter: :any_redis_cable`.

**NOTE:** If you use `graphql-anycable`, things become more complicated. You will need to schemas with different subscriptions providers and a similar dual adapter to support both _cables_.

## Links

- [Demo application](https://github.com/anycable/anycable_rails_demo)
