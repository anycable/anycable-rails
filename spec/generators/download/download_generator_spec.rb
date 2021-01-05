# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/generators/anycable/download/download_generator"

describe AnyCableRailsGenerators::DownloadGenerator, type: :generator do
  destination File.expand_path("../../../tmp/basic_rails_app", __dir__)

  let(:gen) { generator }

  before do
    prepare_destination

    FileUtils.cp_r File.expand_path("../../fixtures/basic_rails_app", __dir__),
      File.expand_path("../../../tmp", __dir__)
  end

  it "runs curl with valid url" do
    gen = generator(%w[--os linux --cpu amd64])
    expect(gen)
      .to receive(:download_exe).with(%r{/releases/latest/download/anycable-go-linux-amd64},
        to: "/usr/local/bin",
        file_name: "anycable-go")
    gen.invoke_all
  end

  context "when bin path is provided" do
    it "runs curl with valid url" do
      gen = generator(%w[--os linux --cpu amd64 --bin-path=/usr/cat/bin])
      expect(gen)
        .to receive(:download_exe).with(%r{/releases/latest/download/anycable-go-linux-amd64},
          to: "/usr/cat/bin",
          file_name: "anycable-go")
      silence_stream($stdout) { gen.invoke_all }
    end
  end

  context "when version is provided" do
    specify do
      gen = generator(%w[--os linux --cpu amd64 --version=1.1.2])
      expect(gen)
        .to receive(:download_exe).with(%r{/releases/download/v1.1.2/anycable-go-linux-amd64},
          to: "/usr/local/bin",
          file_name: "anycable-go")
      silence_stream($stdout) { gen.invoke_all }
    end
  end
end
