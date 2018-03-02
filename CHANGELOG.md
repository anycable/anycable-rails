# Change log

## master

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
