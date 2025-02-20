# Authentication

## JWT authentication

[AnyCable JWT](../anycable-go/jwt_identification.md) is the best (both secure and fast) way to authenticate your real-time connections.

With AnyCable Rails, all you need is to configure the AnyCable application secret (`anycable.secret` in credentials or `ANYCABLE_SECRET` env var) and replace the `#action_cable_meta_tag` with `#action_cable_with_jwt_meta_tag`:

```erb
<%= action_cable_with_jwt_meta_tag(user: current_user, tenant: Current.tenant) %>

# => <meta name="action-cable-url" content="ws://demo.anycable.io/cable?token=eyJhbGciOiJIUzI1NiJ9....EWCEzziOx3sKyMoNzBt20a3QvhEdxJXCXaZsA-f-UzU" />
```

You MUST pass current user's **connection identifiers** as keyword arguments to provide identity information.

You can also use a separate `#anycable_token_meta_tag` helper to inject the token into the page:

```erb
<%= anycable_token_meta_tag(user: current_user, tenant: Current.tenant) %>

# => <meta name="cable-token" content="<token>" />
```

[AnyCable JS client](https://github.com/anycable/anycable-client) will automatically pick up the token from the `cable-token` meta tag.

_Connection identifiers_ are the connection class parameters you define via the `.identified_by` method and set in the `#connect` method. For example:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :user, :tenant

    def connect
      self.current_user = find_verified_user
      self.tenant = find_current_tenant
    end
  end
end
```

**IMPORTANT:** When using AnyCable JWT, the `Connection#connect` method is never called (for clients using JWT tokens). We associate the connection identifiers with the client at the AnyCable server side and make them accessible in subsequent commands. However, if you have some additional logic in your `Connection#connect` method (e.g., tracking users activity), it won't be preserved.

By default, tokens are valid for **1 hour**. You can change this value by specifying the `jwt_ttl` configuration parameter.

### Manually generating tokens

If you're not using HTML, you can generate AnyCable JWT by using the following API:

```ruby
token = AnyCable::JWT.encode({user: current_user})

# you can also override the global TTL setting via expires_at option
token = AnyCable::JWT.encode({user: current_user}, expires_at: 10.minutes.from_now)
```

### Using AnyCable JWT with Action Cable

You can use AnyCable JWT authentication with Rails Action Cable (especially useful when you're gradually migrating to AnyCable). For that, update your `ApplicationCable::Connection` class as follows:

```diff
 module ApplicationCable
   class Connection < ActionCable::Connection::Base
+    prepend AnyCable::Rails::Ext::JWT
+
     identified_by :user, :tenant

     def connect
+      return identify_from_anycable_jwt! if anycable_jwt_present?
+
       self.current_user = find_verified_user
       self.tenant = find_current_tenant
     end
   end
 end
```

### Tokens expiration

AnyCable server checks a token's TTL, and in case the token is expired, the server disconnects the client with a specific reason: `token_expired`. You can learn more about how to refresh the token in [this post](https://anycable.io/blog/jwt-identification-and-hot-streams/).

## Cookies & session

Cookies and Rails sessions are supported by AnyCable Rails. If you run AnyCable server on a different domain from your Rails application, make sure your cookie store is configured to share cookies between domains. For example, to share cookies with subdomains:

```ruby
config.session_store :cookie_store, key: "_<my-app>_sid", domain: :all
```

## Rack middlewares

If your authentication method relies on non-standard Rack request properties (e.g., `request.env["something"]`) for authentication, you MUST configure AnyCable Rack middleware stack to include required Rack middlewares.

### Devise/Warden

Devise relies on [`warden`](https://github.com/wardencommunity/warden) Rack middleware to authenticate users.

By default, this middleware is automatically added to the AnyCable middleware stack when Devise is present.

You can edit `config/anycable.yml` to disable this behavior by changing the `use_warden_manager` parameter.

```yml
# config/anycable.yml
development:
  use_warden_manager: false
```

And then, you can manually put this code, for example, into an initializer (`config/initializers/anycable.rb`) or any other configuration file.

```ruby
AnyCable::Rails::Rack.middleware.use Warden::Manager do |config|
  Devise.warden_config = config
end
```

Then, you can access the current user via `env["warden"].user(scope)` in your connection class (where `scope` is [Warden scope](https://github.com/wardencommunity/warden/wiki/Scopes), usually, `:user`).
