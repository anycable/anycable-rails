# Action Cable extensions

AnyCable comes with useful Action Cable API extensions which you may use with and without AnyCable server.

## Broadcast API

### Broadcast to objects

> See the [demo](https://github.com/anycable/anycable_rails_demo/pull/34) of using this feature.

AnyCable allows to pass not only strings but arbitrary to `ActionCable.server.broadcast` to represent streams, for example:

```ruby
user = User.first
ActionCable.server.broadcast(user, data)

# or multiple objects
ActionCable.server.broadcast([user, :notifications], data)
```

This is useful in conjunction with AnyCable [signed streams](../anycable-go/signed_streams.md), since you can pass the same objects to the `AnyCable::Rails.signed_stream_name` method or `#signed_stream_name` helper:

```ruby
signed_stream_name([user, :notifications])
```

This feature is available when using AnyCable Rails with the Action Cable server.

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

This feature is only supported when using AnyCable.

## Whispering

> See the [demo](https://github.com/anycable/anycable_rails_demo/pull/34) of using whispering with Rails.

AnyCable supports _whispering_, or client-initiated broadcasts. A typical use-case for whispering is sending typing notifications in messaging apps or sharing cursor positions. Here is an example client-side code leveraging whispers (using [AnyCable JS][anycable-client]):

```js
let channel = cable.subscribeTo("ChatChannel", {id: 42});

channel.on("message", (msg) => {
  if (msg.event === "typing") {
    console.log(`user ${msg.name} is typing`);
  }
})

// publishing whispers
const { user } = getCurrentUser();

channel.whisper({event: "typing", name})
```

You MUST explicitly enable whispers in your channel class as follows:

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    room = Chat::Room.find(params[:id])

    stream_for room, whisper: true
  end
end
```

Adding `whisper: true` to the stream subscription enables **sending** broadcasts for this client; all subscribed client receive whispers (as regular broadcasts).

**IMPORTANT:** There can be only one whisper stream per channel subscription (since from the protocol perspective clients don't know about streams).

**NOTE:** This feature is supported by Action Cable server (when `anycable-rails` is loaded), too.

## Helpers

AnyCable provides a few helpers you can use in your views:

- `action_cable_with_jwt_meta_tag`: an alternative to `action_cable_meta_tag` with [JWT support](./authentication.md#jwt-authentication).

- `signed_stream_name`: generates a signed stream name for [AnyCable signed streams](../anycable-go/signed_streams.md). If you want to generate signed stream names outside of views, you can use the `AnyCable::Rails.signed_stream_name` method.

## Connection mixins

AnyCable Rails comes with a couple of module you can add to your `ApplicationCable::Connection` class to bring AnyCable-specific features to Action Cable (i.e., to use them without AnyCable):

- `AnyCable::Rails::Ext::JWT`: adds AnyCable JWT support (see [more](./authentication.md#jwt-authentication)).

## Signed streams

[AnyCable signed streams](../anycable-go/signed_streams.md) is automatically enabled as soon as you load the `anycable-rails` gem. That means, that you can subscribe to a specific "$pubsub" channel and provide a signed stream name to subscribe to Action Cable updates without creating any channels (similar to how Hotwire works):

```js
const consumer = createConsumer();

const channel = consumer.subscriptions.create({channel: "$pubsub", signed_stream_name: "<signed stream>"});
```

You can enable public (unsigned) streams support by overriding the `#allow_public_streams?` method in your connection class:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    # ...
    def allow_public_streams?
      true
    end
  end
end
```

[anycable-client]: https://github.com/anycable/anycable-client
