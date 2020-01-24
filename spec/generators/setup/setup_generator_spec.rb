# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/rails/generators/anycable/setup/setup_generator"

describe AnyCableRailsGenerators::SetupGenerator, type: :generator do
  destination File.expand_path("../../../tmp/basic_rails_app", __dir__)

  let(:gen) { generator }
  let(:base_root) { File.expand_path("../../../tmp/basic_rails_app", __dir__) }
  let(:removed_files) { [] }

  before do
    prepare_destination

    FileUtils.cp_r File.expand_path("../../fixtures/basic_rails_app", __dir__),
      File.expand_path("../../../tmp", __dir__)

    FileUtils.rm(removed_files.map { |f| File.join(base_root, f) }) if removed_files.any?
  end

  context "when skip install environment" do
    before { run_generator %w[--method skip --skip-heroku] }

    it "copies config files" do
      expect(file("config/cable.yml")).to exist
      expect(file("config/anycable.yml")).to exist
    end

    it "patch environment configs" do
      expect(file("config/environments/development.rb"))
        .to contain('config.action_cable.url = ENV.fetch("CABLE_URL", "ws://localhost:3334/cable").presence')

      expect(file("config/environments/production.rb"))
        .to contain('config.action_cable.url = ENV["CABLE_URL"].presence')
    end
  end

  context "when docker environment" do
    it "shows a Docker Compose snippet" do
      gen = generator(%w[--method docker --skip-heroku])
      expect(gen).to receive(:install_for_docker)
      silence_stream(STDOUT) { gen.invoke_all }
    end
  end

  context "when local environment" do
    context "when do not install the server" do
      before { run_generator %w[--method local --source skip --skip-heroku --skip-procfile-dev false] }

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
        gen = generator(%w[--method local --source binary --os linux --cpu amd64 --skip-heroku --skip-procfile-dev false])
        expect(gen)
          .to receive(:download_exe).with(/releases\/download\/v\d+\.\d+\.\d+\/anycable-go-v\d+\.\d+\.\d+-linux-amd64/,
            to: "/usr/local/bin",
            file_name: "anycable-go")
        silence_stream(STDOUT) { gen.invoke_all }
      end
    end

    context "when installin from Homebrew" do
      it "runs commands" do
        gen = generator(%w[--method local --source brew --skip-heroku --skip-procfile-dev false])
        expect(gen).to receive(:install_from_brew)
        silence_stream(STDOUT) { gen.invoke_all }
      end
    end
  end
end
