# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

    DOCS_ROOT = "https://docs.anycable.io"
    DEVELOPMENT_METHODS = %w[skip local docker].freeze
    RPC_IMPL = %w[grpc http].freeze

    class_option :devenv,
      type: :string,
      desc: "Select your development environment (options: #{DEVELOPMENT_METHODS.join(", ")})"
    class_option :rpc,
      type: :string,
      desc: "Select RPC implementation (options: #{RPC_IMPL.join(", ")})",
      default: "grpc"
    class_option :skip_heroku,
      type: :boolean,
      desc: "Do not copy Heroku configs"
    class_option :skip_procfile_dev,
      type: :boolean,
      desc: "Do not create Procfile.dev"
    class_option :skip_jwt,
      type: :boolean,
      desc: "Do not install anycable-rails-jwt"
    class_option :skip_install,
      type: :boolean,
      desc: "Do not run bundle install when adding new gems"
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
            config.action_cable.url = ActionCable.server.config.url = ENV.fetch("CABLE_URL", "/cable") if AnyCable::Rails.enabled?
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
        answer = ask "Do you want to run anycable-go locally or as a Docker container? (1) Local, (2) Docker, (0) Skip"
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
        next if http_rpc?

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

      say_status :help, "⚠️  Please, check out the documentation on using AnyCable with Stimulus Reflex: #{DOCS_ROOT}/rails/stimulus_reflex"
    end

    def rubocop_compatibility
      return unless rubocop?

      say_status :info, "🤖 Running static compatibility checks with RuboCop"
      res = run "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' --only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"
      say_status :help, "⚠️  Please, take a look at the icompatibilities above and fix them. See #{DOCS_ROOT}/rails/compatibility" unless res
    end

    def jwt
      return if options[:skip_jwt]

      return unless options[:skip_jwt] == false || yes?("Do you want to use JWT for authentication? [Yn]")

      opts = " --skip-install" if options[:skip_install]

      run "bundle add anycable-rails-jwt#{opts}"
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

    def nats?
      !!gemfile_lock&.match?(/^\s+nats-pure\b/)
    end

    def webpacker?
      !!gemfile_lock&.match?(/^\s+webpacker\b/)
    end

    def rubocop?
      !!gemfile_lock&.match?(/^\s+rubocop\b/)
    end

    def http_rpc?
      options[:rpc] == "http"
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
          image: anycable/anycable-go:1.4
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
      inside("bin") do
        template "anycable-go"
        chmod "anycable-go", 0755, verbose: false # rubocop:disable Style/NumericLiteralPrefix
      end

      if file_exists?(".gitignore")
        append_file ".gitignore", "bin/dist\n"
      end

      template_proc_files
    end

    def template_proc_files
      file_name = "Procfile.dev"

      if file_exists?(file_name)
        unless http_rpc?
          append_file file_name, "anycable: bundle exec anycable\n", force: true
        end
        append_file file_name, "ws: bin/anycable-go #{anycable_go_options}", force: true
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

    def anycable_go_options
      opts = ["--port=8080"]
      opts << "--broadcast_adapter=http" unless redis?
      opts << "--rpc_impl=http --rpc_host=http://localhost:3000/_anycable" if http_rpc?
      opts.join(" ")
    end

    def file_exists?(name)
      in_root do
        return File.file?(name)
      end
    end

    def anycable_go_version
      @anycable_go_version ||= normalize_version(options[:version]) || "latest"
    end

    def normalize_version(version)
      return unless version

      # We need a full version for bin/anycable-go script
      segments = Gem::Version.new(version).segments
      segments << 0 until segments.size >= 3
      segments.join(".")
    end
  end
end
