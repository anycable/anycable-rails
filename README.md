[![Gem Version](https://badge.fury.io/rb/anycable-rails.svg)](https://rubygems.org/gems/anycable-rails)
[![Build](https://github.com/anycable/anycable-rails/workflows/Build/badge.svg)](https://github.com/anycable/anycable-rails/actions)
[![Gitter](https://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/anycable/Lobby)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://docs.anycable.io/#/rails/getting_started)

# AnyCable Rails

AnyCable allows you to use any WebSocket server (written in any language) as a replacement for built-in Rails Action Cable server.

With AnyCable you can use channels, client-side JS, broadcasting - (almost) all that you can do with Action Cable.

You can even use Action Cable in development and not be afraid of [compatibility issues](#compatibility).

**Important** This is a readme for the upcoming v1.0 release. For v0.6.x see the readme from the [0-6-stable](https://github.com/anycable/anycable-rails/tree/0-6-stable) branch.

💾 [Example Application](https://github.com/anycable/anycable_rails_demo)

📑 [Documentation](https://docs.anycable.io/#/rails/getting_started).

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Requirements

- Ruby >= 2.5
- Rails >= 5.2
- Redis (see [other options](https://github.com/anycable/anycable/issues/2) for broadcasting)

## Usage

Add `anycable-rails` gem to your Gemfile:

```ruby
gem "anycable-rails"

# when using Redis broadcast adapter
gem "redis", ">= 4.0"
```

### Interactive set up

After the gem was installed, you can run an interactive wizard to configure your Rails application for using with AnyCable by running a generator:

```sh
bundle exec rails g anycable:setup
```

### Manual set up

Specify AnyCable subscription adapter for Action Cable:

```yml
# config/cable.yml
development:
  adapter: any_cable # or anycable

production:
  adapter: any_cable
```

and specify AnyCable WebSocket server URL:

```ruby
# For development it's likely the localhost

# config/environments/development.rb
config.action_cable.url = "ws://localhost:3334/cable"

# For production it's likely to have a sub-domain and secure connection

# config/environments/production.rb
config.action_cable.url = "wss://ws.example.com/cable"
```

Then, run AnyCable RPC server:

```sh
$ bundle exec anycable

# don't forget to provide Rails env

$ RAILS_ENV=production bundle exec anycable
```

And, finally, run AnyCable WebSocket server, e.g. [anycable-go](https://docs.anycable.io/#/v1/anycable-go/getting_started):

```sh
anycable-go --host=localhost --port=3334
```

See [documentation](https://docs.anycable.io/#/rails/getting_started) for more information on AnyCable + Rails usage.

## Action Cable Compatibility

See [documentation](https://docs.anycable.io/#/rails/compatibility).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/anycable/anycable-rails](https://github.com/anycable/anycable-rails).

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Security Contact

To report a security vulnerability, please contact us at `anycable@evilmartians.com`. We will coordinate the fix and disclosure.
