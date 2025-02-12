# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/generators/anycable/setup/setup_generator"

describe AnyCableRailsGenerators::SetupGenerator, type: :generator do
  destination File.expand_path("../../../tmp/basic_rails_app", __dir__)

  let(:gen) { generator }
  let(:removed_files) { [] }

  before do
    prepare_destination

    FileUtils.cp_r File.expand_path("../../fixtures/basic_rails_app", __dir__),
      File.expand_path("../../../tmp", __dir__)

    FileUtils.rm(removed_files.map { |f| File.join(destination_root, f) }) if removed_files.any?
  end

  let(:default_opts) { %w[--rpc grpc --devenv skip] }

  context "when skip install environment" do
    subject { run_generator default_opts }

    it "generates config files" do
      subject
      expect(file("config/cable.yml")).to exist
      expect(file("config/cable.yml")).to contain(%(adapter: <%= ENV.fetch("ACTION_CABLE_ADAPTER", "any_cable") %>))
      expect(file("config/anycable.yml")).to contain("broadcast_adapter: http")
      expect(file("anycable.toml")).to contain('broadcast_adapters = ["http"]')
    end

    context "when cable.yml is present" do
      before do
        File.write(
          File.join(destination_root, "config/cable.yml"),
          <<~YML
            default: &default
              adapter: redis
              url: redis://localhost:6379

            development:
              <<: *default
              channel_prefix: campfire_development

            test:
              adapter: test

            performance:
              <<: *default
              channel_prefix: campfire_performance

            production:
              <<: *default
              channel_prefix: campfire_production
          YML
        )
      end

      subject do
        run_generator default_opts
        file("config/cable.yml")
      end

      it "updates cable.yml contents" do
        is_expected.to exist

        is_expected.to contain(%(adapter: <%= ENV.fetch("ACTION_CABLE_ADAPTER", "any_cable") %>))
        is_expected.to contain("channel_prefix: campfire_production")
        is_expected.to contain("channel_prefix: campfire_development")
        is_expected.to contain("adapter: test")
      end
    end

    context "when redis is in the deps" do
      before do
        File.write(
          File.join(destination_root, "Gemfile.lock"),
          <<~CODE
            GEM
              specs:
                redis
          CODE
        )
      end

      it "uses redisx broadcast adapter" do
        subject
        expect(file("config/anycable.yml")).not_to contain("broadcast_adapter: http")
        expect(file("config/anycable.yml")).to contain("broadcast_adapter: redisx")
        expect(file("anycable.toml")).to contain('broadcast_adapters = ["http", "redisx"]')
        expect(file("anycable.toml")).to contain('pubsub_adapter = "redis"')
      end
    end

    context "when using HTTP RPC" do
      subject { run_generator default_opts + %w[--rpc http] }

      it "anycable.yml use redis broadcast adapter" do
        subject
        expect(file("config/anycable.yml")).to contain(%(  http_rpc_mount_path: "/_anycable"))
        expect(file("anycable.toml")).to contain('host = "http://localhost:3000/_anycable"')
      end
    end

    context "warning messages" do
      let(:gen) { generator(default_opts) }

      specify "warn about action_cable in application.rb" do
        out = capture(:stdout) { gen.invoke_all }
        expect(out).to include('Add `require "action_cable/engine"`')
      end

      specify "action_cable_meta_tag" do
        out = capture(:stdout) { gen.invoke_all }
        expect(out).to include("make sure you have `action_cable_meta_tag`")
      end
    end
  end

  context "when docker environment" do
    it "shows a Docker Compose snippet" do
      gen = generator(default_opts + %w[--devenv=docker])
      expect(gen).to receive(:install_for_docker)
      silence_stream($stdout) { gen.invoke_all }
    end
  end

  context "when local environment" do
    let(:opts) { %w[--devenv local] }
    let(:version) { "latest" }

    subject do
      gen = generator(default_opts + opts)
      expect(gen)
        .to receive(:generate).with("anycable:bin", "--version #{version}")
      silence_stream($stdout) { gen.invoke_all }
      file("Procfile.dev")
    end

    context "when Procfile.dev exists" do
      it "patches" do
        expect(subject)
          .to contain("anycable: bundle exec anycable")
        expect(subject)
          .to contain("ws: bin/anycable-go")
      end
    end

    context "when Procfile.dev is absent" do
      let(:removed_files) { %w[Procfile.dev] }

      it "creates" do
        expect(subject)
          .to contain("anycable: bundle exec anycable")
        expect(subject)
          .to contain("ws: bin/anycable-go")
      end

      context "when redis is in the deps" do
        before do
          File.write(
            File.join(destination_root, "Gemfile.lock"),
            <<~CODE
              GEM
                specs:
                  redis
            CODE
          )
        end

        it "creates" do
          expect(subject)
            .to contain("anycable: bundle exec anycable")
          expect(subject)
            .to contain("ws: bin/anycable-go")
        end
      end

      context "when using HTTP rpc" do
        before { opts << "--rpc=http" }

        it "creates" do
          expect(subject)
            .not_to contain("anycable: bundle exec anycable")
          expect(subject)
            .to contain("ws: bin/anycable-go")
        end
      end
    end
  end

  context "when RuboCop is present" do
    before do
      File.write(
        File.join(destination_root, "Gemfile.lock"),
        <<~CODE
          GEM
            specs:
              rubocop
        CODE
      )
    end

    it "runs compatibility checks" do
      gen = generator default_opts
      expect(gen)
        .to receive(:run).with(
          "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' " \
          "--only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"
        )
      silence_stream($stdout) { gen.invoke_all }
    end
  end
end
