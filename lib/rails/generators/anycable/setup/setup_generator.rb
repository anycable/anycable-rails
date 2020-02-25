# frozen_string_literal: true

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

    METHODS = %w[skip local docker].freeze
    # TODO(release): change to latest release
    SERVER_VERSION = "v1.0.0.preview1"
    OS_NAMES = %w[linux darwin freebsd win].freeze
    CPU_NAMES = %w[amd64 arm64 386 arm].freeze
    SERVER_SOURCES = %w[skip brew binary].freeze
    DEFAULT_BIN_PATH = "/usr/local/bin"

    class_option :method,
      type: :string,
      desc: "Select your development environment (options: #{METHODS.join(", ")})"
    class_option :source,
      type: :string,
      desc: "Choose a way of installing AnyCable-Go server (options: #{SERVER_SOURCES.join(", ")})"
    class_option :bin_path,
      type: :string,
      desc: "Where to download AnyCable-Go server binary (default: #{DEFAULT_BIN_PATH})"
    class_option :os,
      type: :string,
      desc: "Specify the OS for AnyCable-Go server binary (options: #{OS_NAMES.join(", ")})"
    class_option :cpu,
      type: :string,
      desc: "Specify the CPU architecturefor AnyCable-Go server binary (options: #{CPU_NAMES.join(", ")})"
    class_option :skip_heroku,
      type: :boolean,
      desc: "Do not copy Heroku configs"
    class_option :skip_procfile_dev,
      type: :boolean,
      desc: "Do not create Procfile.dev"

    def welcome
      say "👋 Welcome to AnyCable interactive installer."
    end

    def configs
      inside("config") do
        template "cable.yml"
        template "anycable.yml"
      end
    end

    def cable_url
      environment(nil, env: :development) do
        <<~SNIPPET
          # Specify AnyCable WebSocket server URL to use by JS client
          config.action_cable.url = ENV.fetch("CABLE_URL", "ws://localhost:3334/cable").presence
        SNIPPET
      end

      environment(nil, env: :production) do
        <<~SNIPPET
          # Specify AnyCable WebSocket server URL to use by JS client
          config.action_cable.url = ENV["CABLE_URL"].presence
        SNIPPET
      end

      say_status :info, "✅ 'config.action_cable.url' has been configured"
      say_status :help, "⚠️ If you're using JS client make sure you have " \
                        "`action_cable_meta_tag` included before any <script> tag in your application.html"
    end

    def development_method
      answer = METHODS.index(options[:method]) || 99

      until METHODS[answer.to_i]
        answer = ask "Which environment do you use for development? (1) Local, (2) Docker, (0) Skip"
      end

      case env = METHODS[answer.to_i]
      when "skip"
        say_status :help, "⚠️ Please, read this guide on how to install AnyCable-Go server 👉 https://docs.anycable.io/#/anycable-go/getting_started", :yellow
      else
        send "install_for_#{env}"
      end
    end

    def heroku
      if options[:skip_heroku].nil?
        return unless yes? "Do you use Heroku for deployment?"
      elsif options[:skip_heroku]
        return
      end

      template "Procfile"
      inside("bin") { template "heroku-web" }

      say_status :help, "️️⚠️ Please, read the required steps to configure Heroku applications 👉 https://docs.anycable.io/#/deployment/heroku", :yellow
    end

    def devise
      in_root do
        return unless File.file?("config/initializers/devise.rb")
      end

      inside("config/initializers") do
        template "anycable.rb"
      end

      say_status :info, "✅ config/initializers/anycable.rb with Devise configuration has been added"
    end

    def finish
      say_status :info, "✅ AnyCable has been configured successfully!"
    end

    private

    def stimulus_reflex?
      !gemfile_lock&.match?(/^\s+stimulus_reflex\b/).nil?
    end

    def gemfile_lock
      @gemfile_lock ||= begin
        res = nil
        in_root do
          next unless File.file?("Gemfile.lock")
          res = File.read("Gemfile.lock")
        end
        res
      end
    end

    def install_for_docker
      say_status :help, "️️⚠️ Docker development configuration could vary", :yellow

      say "Here is an example snippet for docker-compose.yml:"
      say <<~YML
        ─────────────────────────────────────────
        anycable-ws:
          image: anycable/anycable-go:v0.6.4
          ports:
            - '3334:3334'
          environment:
            PORT: 3334
            ANYCABLE_REDIS_URL: redis://redis:6379/0
            ANYCABLE_RPC_HOST: anycable-rpc:50051
          depends_on:
            - anycable-rpc
            - redis

        anycable-rpc:
          <<: *backend
          command: bundle exec anycable
          environment:
            <<: *backend_environment
            ANYCABLE_REDIS_URL: redis://redis:6379/0
            ANYCABLE_RPC_HOST: 0.0.0.0:50051
          ports:
            - '50051'
        ─────────────────────────────────────────
      YML
    end

    def install_for_local
      install_server
      template_proc_files
    end

    def install_server
      answer = SERVER_SOURCES.index(options[:source]) || 99

      until SERVER_SOURCES[answer.to_i]
        answer = ask "How do you want to install AnyCable-Go WebSocket server? (1) Homebrew, (2) Download binary, (0) Skip"
      end

      case answer.to_i
      when 0
        say_status :help, "⚠️ Please, read this guide on how to install AnyCable-Go server 👉 https://docs.anycable.io/#/anycable-go/getting_started", :yellow
        return
      else
        return unless send("install_from_#{SERVER_SOURCES[answer.to_i]}")
      end

      say_status :info, "✅ AnyCable-Go WebSocket server has been successfully installed"
    end

    def template_proc_files
      file_name = "Procfile.dev"

      if File.exist?(file_name)
        append_file file_name, 'anycable: bundle exec anycable --server-command "anycable-go --port 3334"'
      else
        say_status :help, "💡 We recommend using Hivemind to manage multiple processes in development 👉 https://github.com/DarthSim/hivemind", :yellow

        if options[:skip_procfile_dev].nil?
          return unless yes? "Do you want to create a '#{file_name}' file?"
        elsif options[:skip_procfile_dev]
          return
        end

        template file_name
      end
    end

    def install_from_brew
      run "brew install anycable-go", abort_on_failure: true
      run "anycable-go -v", abort_on_failure: true
    end

    def install_from_binary
      out = options[:bin_path] if options[:bin_path]
      out ||= "/usr/local/bin" if options[:method] # User don't want interactive mode
      out ||= ask "Please, enter the path to download the AnyCable-Go binary to", default: DEFAULT_BIN_PATH, path: true

      os_name = options[:os] ||
        OS_NAMES.find(&Gem::Platform.local.os.method(:==)) ||
        ask("What is your OS name?", limited_to: OS_NAMES)

      cpu_name = options[:cpu] ||
        CPU_NAMES.find(&current_cpu.method(:==)) ||
        ask("What is your CPU architecture?", limited_to: CPU_NAMES)

      download_exe(
        "https://github.com/anycable/anycable-go/releases/download/#{SERVER_VERSION}/" \
        "anycable-go-#{os_name}-#{cpu_name}",
        to: out,
        file_name: "anycable-go"
      )

      true
    end

    def download_exe(url, to:, file_name:)
      file_path = File.join(to, file_name)

      run "#{sudo(to)}curl -L #{url} -o #{file_path}", abort_on_failure: true
      run "#{sudo(to)}chmod +x #{file_path}", abort_on_failure: true
      run "#{file_path} -v", abort_on_failure: true
    end

    def sudo!(path)
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
