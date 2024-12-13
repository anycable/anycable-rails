# Change log

## master

- Publish RuboCop cops as a separate gem (`rubocop-anycable-rails`). ([@palkan][])

- Upgrade RuboCop cops. ([@palkan][])

## 1.5.4 (2024-10-08)

- Add [actioncable-next](https://github.com/anycable/actioncable-next) support. ([@palkan][])

- Generate `anycable.toml` in `anycable:setup` generator. ([@palkan][])

## 1.5.3 (2024-09-12)

- Set upper limit on supported Rails versions. ([@palkan][])

  The current release series is unlikely to not work with Rails 8. Let's prevent using them together.

## 1.5.2 (2024-07-01)

- Automatically add `Warden::Manager` to the AnyCable middleware stack when Devise is present. ([@lHydra][])

## 1.5.1 (2024-04-05)

- Add `anycable-rails-core.rb` to avoid adding `require: ["anycable-rails"]` to Gemfiles manually. ([@palkan][])

- Mount HTTP RPC independently of the current Action Cable adapter. ([@palkan][])

  This makes it possible to use it in tests without manually adding the middleware.

## 1.5.0 (2024-04-01)

- Allow specifying the _whispering_ stream via `#stream_from(..., whisper: true)`. ([@palkan][])

  You can use specify the stream to use for _whispering_ (client-initiated broadcasts) by adding `whisper: true` to the `#stream_from` (or `#stream_for`) method call.

  NOTE: This feature is only supported when using AnyCable server and ignored otherwise.

- Support passing objects to `ActionCable.server.broadcast`. ([@palkan][])

  Make it possible to call `ActionCable.server.broadcast(user, data)` or `ActionCable.server.broadcast([user, :context], data)`. This is a companion functionality for `#signed_stream_name`.

- Added `websocket_url` configuration option to specify the URL of AnyCable server. ([@palkan][])

  It's used to configure `config.action_cable.url` if AnyCable is activated. No need to set up it manually.

- Added `rails g anycable:bin` to create a binstub to run AnyCable server. ([@palkan][])

- Added signed streams helpers. ([@palkan][])

  You can use `#signed_stream_name(streamable)` to generate a signed stream name.

- Added JWT authentication helpers. ([@palkan][])

  No more need in a separate `anycable-rails-jwt` gem.

## 1.4.5

- Restrict `anycable` gem version.

## 1.4.4 (2024-03-08) 🌷

- Minor fixes

## 1.4.3 (2023-12-13)

- Fix console logging in Rails 7.1 when the app's logger has no broadcast support. ([@palkan][])

## 1.4.2 (2023-10-15)

- Print warning if the database pool size is less than RPC pool size. ([@palkan][])

- Add support for broadcast options (e.g., `exclude_socket`) and `broadcast ..., to_others: true`. ([@palkan][])

- Add `batch_broadcasts` option to automatically batch broadcasts for code wrapped in Rails executor. ([@palkan][])

- Fix broadcast logging in Rails 7.1. ([@iuri-gg][])

## 1.4.1 (2023-09-27)

- Fix compatibility with Rails 7.1. ([@palkan][])

- Upgrade `anycable:setup` generator to support v1.4 features. ([@palkan][])

Add `bin/anycable-go` to use `anycable-go` locally. Add `--rpc=http` to configure for using AnyCable with HTTP RPC.

## 1.4.0 (2023-07-07)

- Add HTTP RPC integration. ([@palkan][])

Specify `http_rpc_mounth_path` in your `anycable.yml` to enable HTTP RPC.

- Fix `anycable:download` command. ([@palkan][])

Detect MacOS arm64, create target bin path if it doesn't exist.

## 1.3.7 (2023-02-28)

- Fix `anycable` gem dependency constraints.

- Require Ruby 2.7+.

## 1.3.6 (2023-02-28)

- Handle `nil` streams gracefully. ([@palkan][])

- Report exceptions via the `Rails.error.report` interface. ([@palkan][])

## 1.3.5 (2023-01-04)

- Make misconfiguration error more informative. ([@palkan][])

## 1.3.4 (2022-06-28)

- Add support and backport for Connection command callbacks. ([@palkan][])

## 1.3.3 (2022-04-20)

- Added `sid` (unique connection identifier) field to the `welcome` message if present. ([@palkan][])

- Fixed handling Ruby Logger incompatible loggers. ([@palkan][])

## 1.3.2 (2022-03-04)

- Allow Ruby 2.6.

## 1.3.1 (2022-02-28)

- Fix Action Cable Channel patch to not change methods signatures. ([@palkan][])

Otherwise it could lead to conflicts with other patches.

## 1.3.0 (2022-02-21)

- Introduce `AnyCable::Rails.extend_adapter!` to make any pubsub adapter AnyCable-compatible. ([@palkan][])

- Refactored Action Cable patching to preserve original functionality and avoid monkey-patching collisions. ([@palkan][])

## 1.2.1 (2022-01-31)

- Add a temporary fix to be compatible with `sentry-rails`. ([@palkan][])

See [#165](https://github.com/anycable/anycable-rails/issues/165).

- Run embedded RPC server only if `any_cable` adapter is used for Action Cable. ([@palkan][])

## 1.2.0 (2021-12-21) 🎄

- Drop Rails 5 support.

- Drop Ruby 2.6 support.

## 1.1.4 (2021-11-11)

- Added `Connection#state_attr_accessor`. ([@palkan][])

## 1.1.3 (2021-10-11)

- Relax Action Cable dependency. ([@palkan][])

Action Cable 5.1 is allowed (though not recommended).

## 1.1.2 (2021-06-23)

- Bring back dependency on `anycable` (instead of `anycable-core`). ([@palkan][])

Make it easier to get started by adding just a single gem.

## 1.1.1 (2021-06-08)

- Updated documentation links in the generator. ([@palkan][])

## 1.1.0 🚸 (2021-06-01)

- No changes since 1.1.0.rc1.1.

## 1.1.0.rc1.1 (2021-05-12)

- Fixed config loading regression introduced in 1.1.0.rc1.

## 1.1.0.rc1 (2021-05-12)

- Adding `anycable` or `grpc` gem as an explicit dependency is required.

Now, `anycable-rails` depends on `anycable-core`, which doesn't include gRPC server implementation.
You should either add `anycable` or `grpc` (>= 1.37) gem as an explicit dependency.

- Add option to embed AnyCable RPC into a Rails server process. ([@palkan][])

Set `embedded: true` in the configuration to launch RPC along with `rails s` (only for Rails 6.1+).

- **Ruby >= 2.6** is required.
- **Rails >= 6.0** is required.

## 1.0.7 (2021-03-05)

- Ruby 3 compatibility. ([@palkan][])

## 1.0.6 (2021-02-25)

- Keep an explicit list of instance vars to ignore in compatibility checks. ([@palkan][])

You can ignore custom vars by adding them to the list: `AnyCable::Compatibility::IGNORE_INSTANCE_VARS << :@my_var`.

## 1.0.5 (2021-02-24)

- Fixed bug with compatibility false negatives in development. ([@palkan][])

See [#151](https://github.com/anycable/anycable-rails/issues/151).

## 1.0.4 (2020-10-02)

- Relax Rails dependencies. ([@palkan][])

Only add `actioncable` and `globalid` as runtime dependencies, not the whole `rails`.

## 1.0.3 (2020-09-16)

- Fixed bug with building a request object when session store is absent. ([@palkan][])

## 1.0.2 (2020-09-08)

- Added missing channel state support to `#unsubscribed` callbacks. ([@palkan][])

## 1.0.1 (2020-07-07)

- Fixed patching Action Cable testing classes. ([@palkan][])

## 1.0.0 (2020-07-01)

- Support `rescue_from` in connections (Rails 6.1). ([@palkan][])

- Make AnyCable patches compatible with Action Cable testing. ([@palkan][])

- Do not add localhost `redis_url` to `anycable.yml` when Docker development method is chosen in `anycable:setup`. ([@palkan][])

- Fix connection identifiers deserialization regression. ([@palkan][])

Using non-strings or non-GlobalId-encoded objects was broken.

- Improve `anycable:setup` generator. ([@palkan][])

Update Docker snippet, do not enable persistent sessions automatically,
fix setting `config.action_cable.url` in environment configuration.

- Add `state_attr_accessor` for channels. ([@palkan][])

Just like `attr_accessor` but "persists" the state between RPC calls.

- Add `Channel#stop_stream_from` support. ([@palkan][])

- Add `RemoteConnections` support. ([@palkan][])

- Add `AnyCable::Rails.enabled?` method which returns true if Action Cable uses AnyCable adapter. ([@palkan][])

- Add `anycable:download` generator to download `anycable-go` binary. ([@palkan][])

- **Ruby 2.5+ is required**. ([@palkan][])

- Support `disconnect` messages. ([@palkan][])

Added in Rails 6 (see [PR#34194](https://github.com/rails/rails/pull/34194)).

- Add ability to persist _dirty_ `request.session` between RPC calls. ([@palkan][])

This feature emulates the Action Cable behaviour where it's possible to use `request.session` as a shared Hash-like store.
This could be used by some applications (e.g., [StimulusReflex](https://github.com/hopsoft/stimulus_reflex)-based).

You must turn this feature on by setting `persistent_session_enabled: true` in the AnyCable configuration.

- Add ability to use Rack middlewares when build a request for a connection. ([@bibendi][])

- Add set up generator to configure a Rails application by running `bin/rails g anycable:setup`. ([@bibendi][])

- Require a minimum version of Ruby when installing the gem. ([@bibendi][])

- Add ability to develop the gem with Docker. ([@bibendi][])

See [Changelog](https://github.com/anycable/anycable-rails/blob/0-6-stable/CHANGELOG.md) for versions <1.0.0.

[@palkan]: https://github.com/palkan
[@alekseyl]: https://github.com/alekseyl
[@DmitryTsepelev]: https://github.com/DmitryTsepelev
[@sponomarev]: https://github.com/sponomarev
[@bibendi]: https://github.com/bibendi
[@lHydra]: http://github.com/lHydra
