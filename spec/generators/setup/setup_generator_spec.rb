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

  context "when skip install environment" do
    subject { run_generator %w[--devenv skip --skip-heroku] }

    it "copies config files" do
      subject
      expect(file("config/cable.yml")).to exist
      expect(file("config/anycable.yml")).to contain("persistent_session_enabled: false")
    end

    context "when stimulus_reflex is in the deps" do
      before do
        File.write(
          File.join(destination_root, "Gemfile.lock"),
          <<~CODE
            GEM
              specs:
                stimulus_reflex
          CODE
        )
      end

      it "anycable.yml enables persistent sessions" do
        subject
        expect(file("config/anycable.yml")).to contain("persistent_session_enabled: true")
      end
    end

    it "patch environment configs" do
      subject
      expect(file("config/environments/development.rb"))
        .to contain('config.action_cable.url = ENV.fetch("CABLE_URL", "ws://localhost:3334/cable").presence')

      expect(file("config/environments/production.rb"))
        .to contain('config.action_cable.url = ENV["CABLE_URL"].presence')
    end
  end

  context "when docker environment" do
    it "shows a Docker Compose snippet" do
      gen = generator(%w[--devenv docker --skip-heroku])
      expect(gen).to receive(:install_for_docker)
      silence_stream(STDOUT) { gen.invoke_all }
    end
  end

  context "when Heroku deployment" do
    subject { run_generator %w[--devenv skip --skip-heroku=false] }

    before do
      File.write(
        File.join(destination_root, "Procfile"),
        <<~CODE
          web: bundle exec puma -C config/puma.rb
          worker: bundle exec lowkiq
          release: bundle exec rails db:migrate
        CODE
      )
    end

    it "updates Procfile", :aggregate_failures do
      subject
      expect(file("Procfile")).to contain(
        'web: [[ "$ANYCABLE_DEPLOYMENT" == "true" ]] && bundle exec anycable --server-command="anycable-go" || bundle exec puma -C config/puma.rb'
      )
      expect(file("Procfile")).to contain(
        "worker: bundle exec lowkiq"
      )
      expect(file("Procfile")).to contain(
        "release: bundle exec rails db:migrate"
      )
    end
  end

  context "when local environment" do
    context "when do not install the server" do
      before { run_generator %w[--devenv local --source skip --skip-heroku --skip-procfile-dev false] }

      context "when Procfile.dev exists" do
        it "patches" do
          expect(file("Procfile.dev"))
            .to contain('anycable: bundle exec anycable --server-command "anycable-go --port 3334"')
        end
      end

      context "when Procfile.dev absents" do
        let(:removed_files) { %w[Procfile.dev] }

        it "creates" do
          expect(file("Procfile.dev"))
            .to contain('anycable: bundle exec anycable --server-command "anycable-go --port 3334"')
        end
      end
    end

    context "when downloading binary" do
      it "runs curl with valid url" do
        gen = generator(%w[--devenv local --source binary --os linux --cpu amd64 --skip-heroku --skip-procfile-dev false])
        expect(gen)
          .to receive(:generate).with("anycable:download", "--os linux --cpu amd64 --bin-path=/usr/local/bin")
        silence_stream(STDOUT) { gen.invoke_all }
      end
    end

    context "when installing from Homebrew" do
      it "runs commands" do
        gen = generator(%w[--devenv local --source brew --skip-heroku --skip-procfile-dev false])
        expect(gen).to receive(:install_from_brew)
        silence_stream(STDOUT) { gen.invoke_all }
      end
    end
  end

  context "config/initializers/anycable.rb" do
    subject do
      run_generator %w[--devenv skip --skip-heroku]
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
          File.join(destination_root, "config/initializers/devise.rb"),
          <<~CODE
            # devise config
          CODE
        )
      end

      it "creates anycable.rb initializer" do
        expect(subject)
          .to contain("AnyCable::Rails::Rack.middleware.use Warden::Manager")
      end
    end
  end
end
