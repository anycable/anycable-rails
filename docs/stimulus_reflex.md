# Using with Stimulus Reflex

AnyCable v1.0+ works with Stimulus Reflex with some additional considerations:

- For Stimulus Reflex <3, you should add `persistent_session_enabled: true` to your configuration (e.g., `anycable.yml`)
- Stimulus Reflex 3+ persists session by itself but requires you to use a cache store for sessions. **Using memory store is not compatible with AnyCable**. Memory store is only accessible by the owner process, and with AnyCable you have two processes at least (web server and RPC server). Thus, you need to use a distributed cache store such as Redis cache store.

## Links

- [Stimulus Reflex AnyCable deployment documentation](https://docs.stimulusreflex.com/deployment#anycable)
- [Stimulus Reflex Expo configured to run on AnyCable](https://github.com/anycable/stimulus_reflex_expo)
- [Original issue & discussion](https://github.com/hopsoft/stimulus_reflex/issues/46)
- [Issue with a cache store](https://github.com/anycable/anycable-rails/issues/127)
