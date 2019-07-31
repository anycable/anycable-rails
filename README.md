[![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/anycable/anycable/master?grs=github) [![Gem Version](https://badge.fury.io/rb/anycable-rails.svg)](https://rubygems.org/gems/anycable-rails) [![Build Status](https://travis-ci.org/anycable/anycable-rails.svg?branch=master)](https://travis-ci.org/anycable/anycable-rails)
[![Gitter](https://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/anycable/Lobby)
[![Documentation](https://img.shields.io/badge/docs-link-brightgreen.svg)](https://docs.anycable.io/#using_with_rails)

# AnyCable Rails

AnyCable allows you to use any WebSocket server (written in any language) as a replacement for built-in Rails Action Cable server.

With AnyCable you can use channels, client-side JS, broadcasting - (almost) all that you can do with Action Cable.

You can even use Action Cable in development and not be afraid of [compatibility issues](#compatibility).

💾 [Example Application](https://github.com/anycable/anycable_demo)

📑 [Documentation](https://docs.anycable.io).


<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Requirements

- Ruby ~> 2.4; **NOTE:** for Ruby 2.6 use RC version of `google-protobuf` gem. In your Gemfile: `gem "google-protobuf", '>=3.7.0.rc.2'`
- Rails ~> 5.0;
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

Next, specify AnyCable subscription adapter for Action Cable:

```yml
# config/cable.yml
production:
  adapter: any_cable # or anycable
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

```ruby
$ bundle exec anycable

# don't forget to provide Rails env

$ RAILS_ENV=production bundle exec anycable
```

And, finally, run AnyCable WebSocket server, e.g. [anycable-go](https://docs.anycable.io/#go_getting_started.md):

```sh
anycable-go --host=localhost --port=3334
```

See [documentation](https://docs.anycable.io/#using_with_rails) for more information on AnyCable + Rails usage.

## Action Cable Compatibility

See [documentation](https://docs.anycable.io/#compatibility).

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

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
