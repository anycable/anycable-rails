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

      it "anycable.yml use redis broadcast adapter" do
        subject
        expect(file("config/anycable.yml")).not_to contain("broadcast_adapter: http")
        expect(file("config/anycable.yml")).to contain("broadcast_adapter: redis")
      end
    end

    context "when using HTTP RPC" do
      subject { run_generator default_opts + %w[--rpc http] }

      it "anycable.yml use redis broadcast adapter" do
        subject
        expect(file("config/anycable.yml")).to contain(%(  http_rpc_mount_path: "/_anycable"))
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
          .to contain("ws: bin/anycable-go --port=8080 --broadcast_adapter=http")
      end
    end

    context "when Procfile.dev is absent" do
      let(:removed_files) { %w[Procfile.dev] }

      it "creates" do
        expect(subject)
          .to contain("anycable: bundle exec anycable")
        expect(subject)
          .to contain("ws: bin/anycable-go --port=8080 --broadcast_adapter=http")
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
            .to contain("ws: bin/anycable-go --port=8080\n")
        end
      end

      context "when using HTTP rpc" do
        before { opts << "--rpc=http" }

        it "creates" do
          expect(subject)
            .not_to contain("anycable: bundle exec anycable")
          expect(subject)
            .to contain("ws: bin/anycable-go --port=8080 --broadcast_adapter=http --rpc_host=http://localhost:3000/_anycable\n")
        end
      end
    end
  end

  context "config/initializers/anycable.rb" do
    subject do
      run_generator default_opts
      file("config/initializers/anycable.rb")
    end

    context "when no devise.rb" do
      it "doesn't create anycable.rb initializer" do
        expect(subject).not_to exist
      end
    end

    context "when has devise.rb" do
      before do
        File.write(
          File.join(destination_root, "Gemfile.lock"),
          <<~CODE
            GEM
              specs:
                devise
          CODE
        )
      end

      it "creates anycable.rb initializer" do
        expect(subject)
          .to contain("AnyCable::Rails::Rack.middleware.use Warden::Manager")
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
