# Change log

## 🚧 1.0.0 (_coming soon_)

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
