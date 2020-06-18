# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

    DOCS_ROOT = "https://docs.anycable.io/v1/#"
    DEVELOPMENT_METHODS = %w[skip local docker].freeze
    SERVER_SOURCES = %w[skip brew binary].freeze

    class_option :devenv,
      type: :string,
      desc: "Select your development environment (options: #{DEVELOPMENT_METHODS.join(", ")})"
    class_option :source,
      type: :string,
      desc: "Choose a way of installing AnyCable-Go server (options: #{SERVER_SOURCES.join(", ")})"
    class_option :skip_heroku,
      type: :boolean,
      desc: "Do not copy Heroku configs"
    class_option :skip_procfile_dev,
      type: :boolean,
      desc: "Do not create Procfile.dev"

    include WithOSHelpers

    class_option :bin_path,
      type: :string,
      desc: "Where to download AnyCable-Go server binary (default: #{DEFAULT_BIN_PATH})"
    class_option :version,
      type: :string,
      desc: "Specify the AnyCable-Go version (defaults to latest release)"

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
          config.after_initialize do
            config.action_cable.url = ActionCable.server.config.url = ENV.fetch("CABLE_URL", "ws://localhost:8080/cable") if AnyCable::Rails.enabled?
          end
        SNIPPET
      end

      environment(nil, env: :production) do
        <<~SNIPPET
          # Specify AnyCable WebSocket server URL to use by JS client
          config.after_initialize do
            config.action_cable.url = ActionCable.server.config.url = ENV.fetch("CABLE_URL") if AnyCable::Rails.enabled?
          end
        SNIPPET
      end

      say_status :info, "✅ 'config.action_cable.url' has been configured"
      say_status :help, "⚠️  If you're using JS client make sure you have " \
                        "`action_cable_meta_tag` included before any <script> tag in your application.html"
    end

    def development_method
      answer = DEVELOPMENT_METHODS.index(options[:devenv]) || 99

      until DEVELOPMENT_METHODS[answer.to_i]
        answer = ask "Which environment do you use for development? (1) Local, (2) Docker, (0) Skip"
      end

      case env = DEVELOPMENT_METHODS[answer.to_i]
      when "skip"
        say_status :help, "⚠️  Please, read this guide on how to install AnyCable-Go server 👉 #{DOCS_ROOT}/anycable-go/getting_started", :yellow
      else
        send "install_for_#{env}"
      end
    end

    def heroku
      if options[:skip_heroku].nil?
        return unless yes? "Do you use Heroku for deployment? [Yn]"
      elsif options[:skip_heroku]
        return
      end

      in_root do
        next unless File.file?("Procfile")

        contents = File.read("Procfile")
        contents.sub!(/^web: (.*)$/, %q(web: [[ "$ANYCABLE_DEPLOYMENT" == "true" ]] && bundle exec anycable --server-command="anycable-go" || \1))
        File.write("Procfile", contents)
        say_status :info, "✅ Procfile updated"
      end

      say_status :help, "️️⚠️  Please, read the required steps to configure Heroku applications 👉 #{DOCS_ROOT}/deployment/heroku", :yellow
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

    def stimulus_reflex
      return unless stimulus_reflex?

      say_status :help, "⚠️  Please, check out the documentation on using AnyCable with Stimulus Reflex: https://docs.anycable.io/v1/#/ruby/stimulus_reflex"
    end

    def rubocop_compatibility
      return unless rubocop?

      say_status :info, "🤖 Running static compatibility checks with RuboCop"
      res = run "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' --only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"
      say_status :help, "⚠️  Please, take a look at the icompatibilities above and fix them. See https://docs.anycable.io/v1/#/ruby/compatibility" unless res
    end

    def finish
      say_status :info, "✅ AnyCable has been configured successfully!"
    end

    private

    def stimulus_reflex?
      !!gemfile_lock&.match?(/^\s+stimulus_reflex\b/)
    end

    def redis?
      !!gemfile_lock&.match?(/^\s+redis\b/)
    end

    def rubocop?
      !!gemfile_lock&.match?(/^\s+rubocop\b/)
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
      # Remove localhost from configuraiton
      gsub_file "config/anycable.yml", /^.*redis_url:.*localhost[^\n]+\n/, ""

      say_status :help, "️️⚠️  Docker development configuration could vary", :yellow

      say "Here is an example snippet for docker-compose.yml:"
      say <<~YML
        ─────────────────────────────────────────
        ws:
          image: anycable/anycable-go:1.0
          ports:
            - '8080:8080'
          environment:
            ANYCABLE_HOST: "0.0.0.0"
            ANYCABLE_REDIS_URL: redis://redis:6379/0
            ANYCABLE_RPC_HOST: anycable:50051
            ANYCABLE_DEBUG: 1
          depends_on:
            redis:
              condition: service_healthy

        anycable:
          <<: *backend
          command: bundle exec anycable
          environment:
            <<: *backend_environment
            ANYCABLE_REDIS_URL: redis://redis:6379/0
            ANYCABLE_RPC_HOST: 0.0.0.0:50051
            ANYCABLE_DEBUG: 1
          ports:
            - '50051'
          depends_on:
            <<: *backend_depends_on
            ws:
              condition: service_started
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
        say_status :help, "⚠️  Please, read this guide on how to install AnyCable-Go server 👉 #{DOCS_ROOT}/anycable-go/getting_started", :yellow
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
      bin_path ||= DEFAULT_BIN_PATH if options[:devenv] # User don't want interactive mode
      bin_path ||= ask "Please, enter the path to download the AnyCable-Go binary to", default: DEFAULT_BIN_PATH, path: true

      generate "anycable:download", download_options(bin_path: bin_path)

      true
    end

    def download_options(**params)
      opts = options.merge(params)
      [].tap do |args|
        args << "--os #{opts[:os]}" if opts[:os]
        args << "--cpu #{opts[:cpu]}" if opts[:cpu]
        args << "--bin-path=#{opts[:bin_path]}" if opts[:bin_path]
        args << "--version #{opts[:version]}" if opts[:version]
      end.join(" ")
    end
  end
end
