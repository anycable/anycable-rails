# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Downloads anycable-go binary
  class DownloadGenerator < ::Rails::Generators::Base
    namespace "anycable:download"

    include WithOSHelpers

    # TODO: change to latest release
    VERSION = "1.0.0.preview1"

    class_option :bin_path,
      type: :string,
      desc: "Where to download AnyCable-Go server binary (default: #{DEFAULT_BIN_PATH})"
    class_option :version,
      type: :string,
      desc: "Specify the AnyCable-Go version (defaults to latest release)"

    def download_bin
      out = options[:bin_path] || DEFAULT_BIN_PATH
      version = options[:version] || VERSION

      download_exe(
        release_url(version),
        to: out,
        file_name: "anycable-go"
      )

      true
    end

    private

    def release_url(version)
      if Gem::Version.new(version).segments.first >= 1
        new_release_url(version)
      else
        legacy_release_url(version)
      end
    end

    def legacy_release_url(version)
      "https://github.com/anycable/anycable-go/releases/download/v#{version}/" \
        "anycable-go-v#{version}-#{os_name}-#{cpu_name}"
    end

    def new_release_url(version)
      "https://github.com/anycable/anycable-go/releases/download/v#{version}/" \
        "anycable-go-#{os_name}-#{cpu_name}"
    end

    def download_exe(url, to:, file_name:)
      file_path = File.join(to, file_name)

      run "#{sudo(to)}curl -L #{url} -o #{file_path}", abort_on_failure: true
      run "#{sudo(to)}chmod +x #{file_path}", abort_on_failure: true
      run "#{file_path} -v", abort_on_failure: true
    end

    def sudo(path)
      sudo = ""
      unless File.writable?(path)
        if yes? "Path is not writable 😕. Do you have sudo privileges?"
          sudo = "sudo "
        else
          say_status :error, "❌ Failed to install AnyCable-Go WebSocket server", :red
          raise StandardError, "Path #{path} is not writable!"
        end
      end

      sudo
    end
  end
end
