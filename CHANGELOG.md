# Change log

## 0.6.0-dev

- Support tagged logging. ([@palkan][])

- Action Cable monkey-patches are only loaded in the context of AnyCable CLI. ([@palkan][])

  No need to think about `requie` and `group` for `anycable-rails`, just add it to Gemfile.

- Add `:any_cable` subscription adapter for Action Cable. ([@palkan][])

  Use `:any_cable` adapter for Action Cable to broadcast data to AnyCable.

  No more `pubsub` monkey-patches 🎉.

- Added Rails executor/reloader support. ([@palkan][])

- **[Breaking]** No more generators. ([@palkan][])

  No need to generate AnyCable runner script since `anycable` gem ships with
  the CLI.

- Add dynamic (`AnyCable::CompatibilityError`) compatibility checks. ([@DmitryTsepelev][])

- Added static (RuboCop) compatibility checks. ([@DmitryTsepelev][])

  See https://github.com/anycable/anycable-rails/issues/52

## 0.5.4 (2018-06-13)

- Fix duplicate logs in development. ([@palkan][])

  Fixes https://github.com/anycable/anycable_demo/issues/5.

## 0.5.3

- Fix return value of `Connection#handle_close`. ([@palkan][])

  Should always be `true`, we do not expect a failure here.

## 0.5.2

- Add config/anycable.yml to Rails generator. ([@alekseyl][])

## 0.5.1

- Improve Rails integration. ([@palkan][])

Log to STDOUT in development.
Make order of initializers more deterministic.
Show warning if AnyCable is loaded after application initialization.

## 0.5.0

- [#17](https://github.com/anycable/anycable-rails/issues/17) Refactor logging. ([@palkan][])

Use Rails logger everywhere.

Add access logs ([anycable/anycable#20](https://github.com/anycable/anycable/issues/20)).

## 0.4.7

- Minor fixes. ([@palkan][])

## 0.4.6

- Disable mounting default Action Cable server when AnyCable is loaded. ([@palkan][])

## 0.4.5

- Handle tagged logger. ([@palkan][])

Ignore tagged logger features ('cause we do not have _persistent_ logger).

## 0.4.4

- Fix bug with ActiveRecord connections (https://github.com/anycable/anycable/issues/9). ([@palkan][])

## 0.4.0

- Initial version. ([@palkan][])

[@palkan]: https://github.com/palkan
[@alekseyl]: https://github.com/alekseyl
[@DmitryTsepelev]: https://github.com/DmitryTsepelev
