# Action Cable Compatibility

This compatibility table shows which Action Cable features supported by `anycable` gem (AnyCable servers may not support some of the features supported by gem).

| Feature                  | Status|
|--------------------------|--------|
| Connection identifiers   | ✅\* |
| Connection request data (cookies, params) | ✅ |
| Disconnect handling | ✅ |
| Subscribe to channels | ✅ |
| Parameterized subscriptions | ✅ |
| Unsubscribe from channels | ✅ |
| [Subscription Instance Variables](http://edgeapi.rubyonrails.org/classes/ActionCable/Channel/Streams.html) | ✅ \*\* |
| Performing Channel Actions | ✅ |
| Streaming | ✅ |
| [Custom stream callbacks](http://edgeapi.rubyonrails.org/classes/ActionCable/Channel/Streams.html) | 🚫 |
| Broadcasting | ✅ |
| Periodical timers | 🚫 |
| Disconnect remote clients | ✅ |
| Command callbacks | ✅ \*\*\* |

\* See [restoring state objects](../architecture.md#restoring-state-objects) for more information on how identifiers work.

\*\* See [channel state](./channels_state.md) for more information on subscription instance variables support.

\*\*\* AnyCable (via `anycable-rails`) also supports [command callbacks](https://github.com/rails/rails/pull/44696) (`before_command`, `after_command`, `around_command`) for older Rails versions (event when not using AnyCable).

## Runtime checks

AnyCable provides a way to enforce compatibility through runtime checks.

Runtime checks are monkey-patches which raise exceptions (`AnyCable::CompatibilityError`) when AnyCable-incompatible code is called.

To enabled runtime checks add the following file to your configuration (e.g. `config/<env>.rb` or `config/initializers/anycable.rb`):

```ruby
require "anycable/rails/compatibility"
```

**NOTE:** compatibility checks could be used with Action Cable (i.e. w/o AnyCable) and don't affect compatible functionality; thus it makes sense to add runtime checks in development and test environments.

For example, the following channel class:

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    @room = ChatRoom.find(params[:id])
  end
end
```

raises `AnyCable::CompatibilityError` when client tries to subscribe to the channel, 'cause AnyCable doesn't support storing channel's state in instance variables.

## RuboCop cops

AnyCable integrates with [RuboCop](https://github.com/rubocop-hq/rubocop) to detect incompatible code in your application.

Add to your `.rubocop.yml`:

```yml
require:
  - "anycable/rails/compatibility/rubocop"
# ...
```

And run `rubocop`:

```sh
$ bundle exec rubocop

#=> app/channels/bad_channel.rb:5:5: C: AnyCable/InstanceVars: Channel instance variables are not supported in AnyCable. Use state_attr_accessor instead.
#=>    @bad_var = "bad"
#=>    ^^^^^^^^^^^^^^^^
```

Or you can require AnyCable cops dynamically:

```sh
bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' --only AnyCable
```

**NOTE**: If you have `DisabledByDefault: true` in your RuboCop config, you need to specify all AnyCable cops explicitly:

```sh
bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' \
--only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars
```

### Cops

#### `AnyCable/InstanceVars`

Checks for instance variable usage inside channels:

```ruby
# bad
class MyChannel < ApplicationCable::Channel
  def subscribed
    @post = Post.find(params[:id])
    stream_from @post
  end
end

# good
class MyChannel < ApplicationCable::Channel
  def subscribed
    post = Post.find(params[:id])
    stream_from post
  end
end
```

#### `AnyCable/StreamFrom`

Checks for `stream_from` calls with custom callbacks or coders:

```ruby
# bad
class MyChannel < ApplicationCable::Channel
  def follow
    stream_from("all") {}
  end
end

class MyChannel < ApplicationCable::Channel
  def follow
    stream_from("all", -> {})
  end
end

class MyChannel < ApplicationCable::Channel
  def follow
    stream_from("all", coder: SomeCoder)
  end
end

# good
class MyChannel < ApplicationCable::Channel
  def follow
    stream_from "all"
  end
end
```

#### `AnyCable/PeriodicalTimers`

Checks for periodical timers usage:

```ruby
# bad
class MyChannel < ApplicationCable::Channel
  periodically(:do_something, every: 2.seconds)
end
```
