[![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/anycable/anycable/master?grs=github) [![Gem Version](https://badge.fury.io/rb/anycable-rails.svg)](https://rubygems.org/gems/anycable-rails) [![Build Status](https://travis-ci.org/anycable/anycable-rails.svg?branch=master)](https://travis-ci.org/anycable/anycable-rails)
[![Gitter](https://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/anycable/Lobby)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://docs.anycable.io/#/ruby/rails)

# AnyCable Rails

AnyCable allows you to use any WebSocket server (written in any language) as a replacement for built-in Rails Action Cable server.

With AnyCable you can use channels, client-side JS, broadcasting - (almost) all that you can do with Action Cable.

You can even use Action Cable in development and not be afraid of [compatibility issues](#compatibility).

💾 [Example Application](https://github.com/anycable/anycable_demo)

📑 [Documentation](https://docs.anycable.io).


<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Requirements

- Ruby >= 2.5
- Rails >= 5.0;
- Redis (see [other options]() for broadcasting)

## How It Works?

<img src="https://trello-attachments.s3.amazonaws.com/5781e0ed48e4679e302833d3/820x987/5b6a305417b04e20e75f49c5816e027c/Anycable_vs_ActionCable_copy.jpg" width="400" />

## Usage

Add `anycable-rails` gem to your Gemfile:

```ruby
gem "anycable-rails"

# when using Redis broadcast adapter
gem "redis", ">= 4.0"
```

(and don't forget to run `bundle install`).

### Interactive set up

After the gem was installed, you can run an interactive wizard to configure your Rails application for using with AnyCable by running a generator:

```sh
bin/rails g anycable:setup
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

And, finally, run AnyCable WebSocket server, e.g. [anycable-go](https://docs.anycable.io/#/anycable-go/getting_started):

```sh
anycable-go --host=localhost --port=3334
```

See [documentation](https://docs.anycable.io/#/ruby/rails) for more information on AnyCable + Rails usage.

## Action Cable Compatibility

See [documentation](https://docs.anycable.io/#/ruby/compatibility).

## Links

- [AnyCable: Action Cable on steroids!](https://evilmartians.com/chronicles/anycable-actioncable-on-steroids)

- [From Action to Any](https://medium.com/@leshchuk/from-action-to-any-1e8d863dd4cf) by [@alekseyl](https://github.com/alekseyl)

## Talks

- One cable to rule them all, RubyKaigi 2018, [slides](https://speakerdeck.com/palkan/rubykaigi-2018-anycable-one-cable-to-rule-them-all) and [video](https://www.youtube.com/watch?v=jXCPuNICT8s) (EN)

- Wroc_Love.rb 2018 [slides](https://speakerdeck.com/palkan/wroc-love-dot-rb-2018-cables-cables-cables) and [video](https://www.youtube.com/watch?v=AUxFFOehiy0) (EN)

## Compatible WebSocket servers

- [AnyCable Go](https://github.com/anycable/anycable-go)
- [ErlyCable](https://github.com/anycable/erlycable)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anycable/anycable-rails.

## Development

If you are familiar with Docker, you can use [DIP](https://github.com/bibendi/dip) to start developing the gem quickly.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
