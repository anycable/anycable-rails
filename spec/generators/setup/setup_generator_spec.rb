# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/generators/anycable/setup/setup_generator"
require "toml"

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

  # Read and parse YAML configs to verify the values
  let(:cable_yml) { YAML.load_file(File.join(destination_root, "config/cable.yml"), aliases: true).deep_symbolize_keys }
  let(:anycable_yml) { YAML.load_file(File.join(destination_root, "config/anycable.yml"), aliases: true).deep_symbolize_keys }
  let(:anycable_toml) { TOML.load_file(File.join(destination_root, "anycable.toml")).deep_symbolize_keys }

  # Base options=skip everything, the generator only adds/updates config files
  let(:base_opts) { {rpc: "none", development: "skip"} }
  let(:opts) { {} }

  let(:cli_opts) { base_opts.merge(opts).map { "--#{_1}=#{_2}" } }

  let(:gen) { generator(cli_opts) }

  subject { run_generator cli_opts }

  it "generates config files" do
    subject

    expect(file("config/cable.yml")).to exist

    expect(cable_yml.dig(:development, :adapter)).to eq "any_cable"
    expect(cable_yml.dig(:production, :adapter)).to eq "any_cable"

    expect(anycable_yml.dig(:development, :broadcast_adapter)).to eq "http"
    expect(anycable_yml.dig(:production, :broadcast_adapter)).to eq "http"
    expect(anycable_yml.dig(:development, :secret)).to eq "anycable-local-secret"
    expect(anycable_yml.dig(:production, :secret)).to be_nil

    # We must enable broker by default
    expect(anycable_toml[:presets]).to eq(["broker"])
    expect(anycable_toml[:broadcast_adapters]).to eq(["http"])
    expect(anycable_toml[:secret]).to eq "anycable-local-secret"
    expect(anycable_toml.dig(:rpc, :implementation)).to eq "none"
    # Turbo Streams must be enabled by default
    expect(anycable_toml.dig(:streams, :turbo)).to eq true
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

    it "updates cable.yml contents" do
      subject
      expect(file("config/cable.yml")).to exist

      expect(cable_yml.dig(:development, :adapter)).to eq "any_cable"
      expect(cable_yml.dig(:production, :adapter)).to eq "any_cable"
      expect(cable_yml.dig(:performance, :adapter)).to eq "any_cable"

      # all previous adapter specific options must be removed
      expect(cable_yml.dig(:development, :url)).to be_nil
      expect(cable_yml.dig(:production, :url)).to be_nil
      expect(cable_yml.dig(:performance, :url)).to be_nil

      expect(cable_yml.dig(:production, :channel_prefix)).to eq "campfire_production"
      expect(cable_yml.dig(:performance, :channel_prefix)).to eq "campfire_performance"

      expect(cable_yml.dig(:test, :adapter)).to eq "test"
    end
  end

  context "when using HTTP RPC" do
    let(:opts) { {rpc: "http"} }

    specify do
      subject
      expect(anycable_yml.dig(:development, :http_rpc)).to eq true
      expect(anycable_toml.dig(:rpc, :host)).to eq "http://localhost:3000/_anycable"
    end
  end

  context "when using gRPC" do
    let(:opts) { {rpc: "grpc"} }

    specify do
      subject
      expect(anycable_yml.dig(:development, :http_rpc)).to be_nil
      expect(anycable_toml.dig(:rpc, :host)).to eq "localhost:50051"
    end
  end

  context "action_cable/engine" do
    it "adds to application.rb if missing" do
      subject

      expect(file("config/application.rb")).to contain(%r{^require "action_cable/engine"})
    end

    context "when it's missing and the application.rb is unconventional" do
      before do
        File.write(
          File.join(destination_root, "config/application.rb"),
          <<~RUBY
            require "my_custom_rails"
          RUBY
        )
      end

      specify do
        out = capture(:stdout) { gen.invoke_all }
        expect(out).to include('Add `require "action_cable/engine"`')
      end
    end
  end

  context "action_cable_meta_tag" do
    it "adds to the layout" do
      subject

      expect(file("app/views/layouts/application.html.erb")).to contain(%(<%= action_cable_with_jwt_meta_tag %>))
    end

    context "when no application.html" do
      let(:removed_files) { %w[app/views/layouts/application.html.erb] }

      it "warns when we failed to add it" do
        out = capture(:stdout) { gen.invoke_all }
        expect(out).to include("Ensure you have `action_cable_meta_tag`")
      end
    end

    context "when application.html is non-standard" do
      before do
        File.write(
          File.join(destination_root, "app/views/layouts/application.html.erb"),
          <<~HTML
            <!DOCTYPE html>
            <html>
              <head>
              </head>

              <body>
              </body>
            </html>
          HTML
        )
      end

      it "warns when we failed to add it" do
        out = capture(:stdout) { gen.invoke_all }
        expect(out).to include("Ensure you have `action_cable_meta_tag`")
      end
    end

    context "when using RPC" do
      let(:opts) { {rpc: "http"} }

      it "adds action_cable_meta_tag" do
        subject

        expect(file("app/views/layouts/application.html.erb")).to contain(%(<%= action_cable_meta_tag %>))
      end
    end
  end

  context "when docker environment" do
    let(:opts) { {development: "docker"} }

    it "shows a Docker Compose snippet" do
      expect(gen).to receive(:install_for_docker)
      silence_stream($stdout) { gen.invoke_all }
    end
  end

  context "when local environment" do
    let(:opts) { {development: "local"} }
    let(:version) { "latest" }

    subject do
      expect(gen)
        .to receive(:generate).with("anycable:bin", "--version #{version}")
      silence_stream($stdout) { gen.invoke_all }
      file("Procfile.dev")
    end

    context "when Procfile.dev exists" do
      it "patches" do
        expect(subject)
          .to contain("ws: bin/anycable-go --port 8080")
        expect(subject)
          .not_to contain("anycable: bundle exec anycable")
      end

      context "when using gRPC" do
        let(:opts) { super().merge(rpc: "grpc") }

        it "patches" do
          expect(subject)
            .to contain("anycable: bundle exec anycable")
          expect(subject)
            .to contain("ws: bin/anycable-go --port 8080")
        end
      end
    end

    context "when Procfile.dev is absent" do
      let(:removed_files) { %w[Procfile.dev] }

      it "creates Procfile.dev" do
        expect(subject)
          .to contain("anycable: bundle exec anycable")
        expect(subject)
          .to contain("ws: bin/anycable-go")
      end

      context "with bin/dev" do
        context "when Procfile.dev is mentioned" do
          before do
            File.write(
              File.join(destination_root, "bin/dev"),
              %(exec foreman start -f Procfile.dev "$@")
            )
          end

          it "keeps bin/dev the same" do
            before_bin_dev = File.read(File.join(destination_root, "bin/dev"))
            subject
            after_bin_dev = File.read(File.join(destination_root, "bin/dev"))
            expect(after_bin_dev).to eq(before_bin_dev)
          end
        end

        context "with default bin/rails server" do
          before do
            File.write(
              File.join(destination_root, "bin/dev"),
              %(exec "./bin/rails", "server", *ARGV)
            )
          end

          it "updates bin/dev to use foreman or overmind" do
            subject

            bin_dev = File.read(File.join(destination_root, "bin/dev"))
            expect(bin_dev).to include("foreman start -f Procfile.dev")
            expect(bin_dev).to include("overmind start -f Procfile.dev")
          end
        end
      end
    end
  end

  context "anycable client" do
    before do
      File.write(
        File.join(destination_root, "Gemfile.lock"),
        <<~CODE
          GEM
            specs:
              turbo-rails
        CODE
      )
    end

    it "installs packages with importmap and update the application.js" do
      expect(gen)
        .to receive(:run).with(%r{bin/importmap pin @hotwired/turbo @anycable/web @anycable/turbo-stream})
      silence_stream($stdout) do
        gen.invoke_all
      end
      expect(file("app/javascript/application.js")).to contain(%(import "@hotwired/turbo"))
      expect(file("app/javascript/application.js")).to contain(%(import { start } from "@anycable/turbo-stream"))
      expect(file("app/javascript/application.js")).to contain(%(import { createCable } from "@anycable/web"))
      expect(file("app/javascript/application.js")).to contain(%(const cable = createCable({ protocol: 'actioncable-v1-ext-json' })))
      expect(file("app/javascript/application.js")).to contain(%(start(cable, { delayedUnsubscribe: true })))
    end
  end

  context "Turbo configuration" do
    before do
      File.write(
        File.join(destination_root, "Gemfile.lock"),
        <<~CODE
          GEM
            specs:
              turbo-rails
        CODE
      )
    end

    it "adds config.turbo.signed_stream_verifier_key" do
      subject

      expect(file("config/application.rb")).to contain(%(config.turbo.signed_stream_verifier_key = AnyCable.config.secret))
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
      expect(gen)
        .to receive(:run).with(
          "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' " \
          "--only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"
        )
      silence_stream($stdout) { gen.invoke_all }
    end
  end
end
