# frozen_string_literal: true

module AnyCableRailsGenerators
  module Setup
    # Generator to help set up AnyCable locally
    class LocalGenerator < ::Rails::Generators::Base
      SERVER_VERSION = "v0.6.4"
      OS_NAMES = %w[linux darwin freebsd win].freeze
      CPU_NAMES = %w[amd64 arm64 386 arm].freeze

      namespace "anycable:setup:local"
      source_root File.expand_path("../templates", __dir__)

      def server
        answer = nil

        until [1, 2, 3].include?(answer.to_i)
          answer = ask "How do you want to install AnyCable-Go WebSocket server? (1) Homebrew, (2) Download binary, (3) Skip"
        end

        case answer.to_i
        when 1
          run "brew install anycable-go", abort_on_failure: true
          run "anycable-go -v", abort_on_failure: true
        when 2
          return unless download_binary
        when 3
          say_status :help, "⚠️ Please, read this guide on how to install AnyCable-Go server 👉 https://docs.anycable.io/#/anycable-go/getting_started", :yellow
          return
        else
          raise ArgumentError, "Unknown answer: #{answer}"
        end

        say_status :info, "✅ AnyCable-Go WebSocket server has been successfully installed"
      end

      def proc_files
        file_name = "Procfile.dev"

        if File.exist?(file_name)
          append_file file_name, 'anycable: bundle exec anycable --server-command "anycable-go --port 3334"'
        else
          say_status :help, "💡 We recommend using Hivemind to manage multiple processes in development 👉 https://github.com/DarthSim/hivemind", :yellow

          template file_name if yes? "Do you want to create a '#{file_name}' file?"
        end
      end

      private

      def download_binary
        out_path = ask "Please, enter the path to download the AnyCable-Go binary to", default: "/usr/local/bin", path: true
        file_name = File.join(out_path, "anycable-go")

        sudo = ""
        unless File.writable?(out_path)
          if yes? "Path is not writable 😕. Do you have sudo privileges?"
            sudo = "sudo "
          else
            say_status :error, "❌ Failed to install AnyCable-Go WebSocket server", :red
            return false
          end
        end

        os_name = OS_NAMES.find(&Gem::Platform.local.os.method(:==)) ||
                  ask("What is your OS name?", limited_to: OS_NAMES)

        cpu_name = CPU_NAMES.find(&current_cpu.method(:==)) ||
                   ask("What is your CPU architecture?", limited_to: CPU_NAMES)

        run "#{sudo}curl -L https://github.com/anycable/anycable-go/releases/download/#{SERVER_VERSION}/" \
            "anycable-go-#{SERVER_VERSION}-#{os_name}-#{cpu_name} -o #{file_name}", abort_on_failure: true

        run "#{sudo}chmod +x #{file_name}", abort_on_failure: true
        run "#{file_name} -v", abort_on_failure: true

        true
      end

      def current_cpu
        case Gem::Platform.local.cpu
        when "x86_64", "x64"
          "amd64"
        when "x86_32", "x86", "i386", "i486", "i686"
          "i386"
        when "aarch64", "aarch64_be", /armv8/
          "arm64"
        when "arm", /armv7/, /armv6/
          "arm"
        else
          "unknown"
        end
      end
    end
  end
end
