# Channels State

Since channel classes are ephemeral in AnyCable (see [Architecture](../architecture.md)), the following example wouldn't not work out-of-the-box:

```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    @room = Room.find(params["room_id"])
    stream_for @room
  end

  def speak(data)
    broadcast_to @room, message: data["text"]
  end
end
```

The instance variable `@room` lives only during the `#subscribed` call, it's not set when the `#speak` action is performed, 'cause it happens in the context of the new RoomChannel instance.

The are two ways to fix this: using `params` or using _channel state accessors_.

## Subscription `params`

Subscription parameters are included into the _subscription identifier_, and thus accessible to all RPC requests.

**NOTE**: `params` are read-only.

We can refactor our channel to rely on params instead of instance variables:

```ruby
class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_for params["room_id"]
  end

  def speak(data)
    broadcast_to params["room_id"], message: data["text"]
  end
end
```

## Using `state_attr_accessor`

In case `params` is not enough and you want to mutate the channel state or store non-primitive values, you can use _state accessors_.

State accessor behaves like `attr_accessor` but also persists the data in AnyCable for subsequent calls:

```ruby
class RoomChannel < ApplicationCable::Channel
  state_attr_accessor :room

  def subscribed
    self.room = Room.find(params["room_id"])
    stream_for room
  end

  def speak(data)
    broadcast_to room, message: data["text"]
  end
end
```

Read more about how the state is passed from a WebSocket server and restored in an RPC server in the [architecture overview](../architecture.md#restoring-state-objects).
