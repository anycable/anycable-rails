# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/generators/anycable/bin/bin_generator"

describe AnyCableRailsGenerators::BinGenerator, type: :generator do
  destination File.expand_path("../../../tmp/basic_rails_app", __dir__)

  let(:gen) { generator }
  let(:removed_files) { [] }

  before do
    prepare_destination

    FileUtils.cp_r File.expand_path("../../fixtures/basic_rails_app", __dir__),
      File.expand_path("../../../tmp", __dir__)

    FileUtils.rm(removed_files.map { |f| File.join(destination_root, f) }) if removed_files.any?
  end

  let(:default_opts) { [] }
  let(:opts) { [] }

  subject do
    run_generator default_opts + opts
    file("bin/anycable-go")
  end

  context "when .gitignore" do
    before do
      File.write(
        File.join(destination_root, ".gitignore"),
        <<~CODE
          tmp/
          *.log
        CODE
      )
    end

    it "creates bin/anycable-go" do
      is_expected.to exist
    end

    it "adds bin/dist to .gitignore" do
      subject
      expect(file(".gitignore")).to contain("bin/dist")
    end
  end

  context "without .gitignore" do
    it "creates bin/anycable-go" do
      is_expected.to exist
    end
  end

  context "when version is specified" do
    before { opts << "--version=1.4" }

    it "creates bin/anycable-go with the specified version" do
      subject
      expect(file("bin/anycable-go")).to exist
      expect(file("bin/anycable-go")).to contain("1.4.0")
    end
  end
end
