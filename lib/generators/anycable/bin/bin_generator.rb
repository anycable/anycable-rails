# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Generates bin/anycable-go binstub
  class BinGenerator < ::Rails::Generators::Base
    namespace "anycable:bin"

    source_root File.expand_path("templates", __dir__)

    class_option :version,
      type: :string,
      desc: "Specify AnyCable server version (defaults to latest release)",
      version: "latest"

    def generate_bin
      inside("bin") do
        template "anycable-go"
        chmod "anycable-go", 0755, verbose: false # rubocop:disable Style/NumericLiteralPrefix
      end

      in_root do
        next unless File.file?(".gitignore")

        ignores = File.read(".gitignore").lines

        if ignores.none? { |line| line.match?(/^bin\/dist$/) }
          append_file ".gitignore", "bin/dist\n"
        end
      end

      true
    end

    private

    def anycable_go_version
      @anycable_go_version ||= normalize_version(options[:version]) || "latest"
    end

    def normalize_version(version)
      return unless version
      return if version.chomp == "latest"

      # We need a full version for bin/anycable-go script
      segments = Gem::Version.new(version).segments
      segments << 0 until segments.size >= 3
      segments.join(".")
    end
  end
end
