[![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/anycable/anycable/master?grs=github) [![Gem Version](https://badge.fury.io/rb/anycable-rails.svg)](https://rubygems.org/gems/anycable-rails) [![Build Status](https://travis-ci.org/anycable/anycable-rails.svg?branch=master)](https://travis-ci.org/anycable/anycable-rails) [![Circle CI](https://circleci.com/gh/anycable/anycable-rails/tree/master.svg?style=svg)](https://circleci.com/gh/anycable/anycable-rails/tree/master)
[![Gitter](https://img.shields.io/badge/gitter-join%20chat%20%E2%86%92-brightgreen.svg)](https://gitter.im/anycable/Lobby)

# Anycable Rails

AnyCable allows you to use any WebSocket server (written in any language) as a replacement for built-in Rails ActionCable server.

With AnyCable you can use channels, client-side JS, broadcasting - (almost) all that you can do with ActionCable.

You can even use ActionCable in development and not be afraid of compatibility issues.

[Example Application](https://github.com/anycable/anycable_demo)

For usage outside Rails see [AnyCable repository](https://github.com/anycable/anycable).

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Requirements

- Ruby ~> 2.3;
- Rails ~> 5.0;
- Redis

## How It Works?

<img src="https://trello-attachments.s3.amazonaws.com/5781e0ed48e4679e302833d3/820x987/5b6a305417b04e20e75f49c5816e027c/Anycable_vs_ActionCable_copy.jpg" width="400" />

## Links

- [GitPitch Slides](https://gitpitch.com/anycable/anycable/master?grs=github)

- RailsClub Moscow 2016 [slides](https://speakerdeck.com/palkan/railsclub-moscow-2016-anycable) and [video](https://www.youtube.com/watch?v=-k7GQKuBevY&list=PLiWUIs1hSNeOXZhotgDX7Y7qBsr24cu7o&index=4) (RU)


## Compatible WebSocket servers

- [Anycable Go](https://github.com/anycable/anycable-go)
- [ErlyCable](https://github.com/anycable/erlycable)


## Installation

Add Anycable to your application's Gemfile:

```ruby
gem 'anycable-rails'

# or if you want to use built-in Action Cable server
# for test and development (which is possible and recommended)
gem 'anycable-rails', group: :production
```

And then run:

```shell
rails generate anycable
```

to create executable.

## Configuration

Add `config/anycable.yml`if you want to override defaults (see below):

```yml
production:
  # gRPC server host
  rpc_host: "localhost:50051"
  # Redis URL (for broadcasting) 
  redis_url: "redis://localhost:6379/2"
  # Redis channel name
  redis_channel: "anycable"

```

Anycable uses [anyway_config](https://github.com/palkan/anyway_config), thus it is also possible to set configuration variables through `secrets.yml` or environment vars.

## Usage

Run Anycable RPC server:

```ruby
./bin/anycable
```

and also run AnyCable-compatible WebSocket server, e.g. [anycable-go](https://github.com/anycable/anycable-go):

```sh
anycable-go -addr='localhost:3334'
```

Don't forget to set cable url in your `config/environments/production.rb`:

```ruby
config.action_cable.url = "ws://localhost:3334/cable"
```

### Logging

Anycable uses `Rails.logger` as `Anycable.logger` by default, thus Anycable _debug_ mode (`ANYCABLE_DEBUG=1`) is not available, you should configure Rails logger instead, e.g.:

```ruby
# in Rails configuration
if Anycable.config.debug
  config.logger = Logger.new(STDOUT)
  config.log_level = :debug
end
```

You can also turn on access logging (`Started <request data>` / `Finished <request data>`):

```ruby
# in anycable.yml
production:
  access_logs_disabled: false
```


## ActionCable Compatibility

This is the compatibility list for the AnyCable gem, not for AnyCable servers (which may not support some of the features yet).

Feature                  | Status 
-------------------------|--------
Connection Identifiers   | +
Connection Request (cookies, params) | +
Disconnect Handling | +
Subscribe to channels | +
Parameterized subscriptions | +
Unsubscribe from channels | +
[Subscription Instance Variables](http://edgeapi.rubyonrails.org/classes/ActionCable/Channel/Streams.html) | -
Performing Channel Actions | +
Streaming | +
[Custom stream callbacks](http://edgeapi.rubyonrails.org/classes/ActionCable/Channel/Streams.html) | -
Broadcasting | +
Periodical Timers | -
Disconnect remote clients | -


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/anycable/anycable-rails.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
