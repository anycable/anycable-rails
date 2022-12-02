# Authentication

## Rack middlewares

Most authentication strategies rely on request cookies or session (directly or indirectly).

Cookies and Rails session object are supported in AnyCable out-of-the-box. If you rely on some
other Rack request properties (e.g., `request.env["something"]`) for your authentication, you must configure
AnyCable Rack middleware stack to make them work (because requests in AnyCable are not passed through the default Rails stack).

You can do this through the `AnyCable::Rails::Rack.middleware` object in your configuration. See Devise/Warden example below.

## Devise/Warden

Devise relies on [`warden`](https://github.com/wardencommunity/warden) Rack middleware to authenticate users.

In order to make it work with AnyCable, you must add this middleware to AnyCable's middleware stack like this:

```ruby
AnyCable::Rails::Rack.middleware.use Warden::Manager do |config|
  Devise.warden_config = config
end
```

You can put this code, for example, into an initializer (`config/initializers/anycable.rb`) or any other configuration file.

Then, you can access the current user via `env["warden"].user(scope)` in your connection class (where `scope` is [Warden scope](https://github.com/wardencommunity/warden/wiki/Scopes), usually, `:user`).

### Manually building Warden session

You can also try building a Warden context yourself (e.g., if you use a custom session storage mechanism or other modifications). Here is a real-life example:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      redis = Redis.new(url: ENV["REDIS_URL"])

      # this key should have the same `key_prefix` as setup in redis_session_store config (see above)
      rkey = "xylophone:session:#{cookies[app_cookies_key]}"

      session_data = redis.get(rkey)

      if session_data.present?
        env["rack.session"] = JSON.parse(session_data, quirks_mode: true)
        Warden::SessionSerializer.new(env).fetch(:user)
      else
        reject_unauthorized_connection
      end
    end

    def app_cookies_key
      Rails.application.config.session_options[:key] ||
        raise("No session cookies key in config")
    end
  end
end
```
