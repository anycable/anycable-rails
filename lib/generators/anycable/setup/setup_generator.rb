# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

    DOCS_ROOT = "https://docs.anycable.io"
    DEVELOPMENT_METHODS = %w[skip local docker].freeze
    DEPLOYMENT_METHODS = %w[other fly heroku anycable_plus].freeze
    RPC_IMPL = %w[none grpc http].freeze

    class_option :devenv,
      type: :string,
      desc: "Select your development environment (options: #{DEVELOPMENT_METHODS.reverse.join(", ")})"
    class_option :rpc,
      type: :string,
      desc: "Select RPC implementation (options: #{RPC_IMPL.reverse.join(", ")})"
    class_option :skip_procfile,
      type: :boolean,
      desc: "Do not create/update Procfile.dev"
    class_option :version,
      type: :string,
      desc: "Specify AnyCable server version (defaults to latest release)",
      default: "latest"

    def welcome
      say ""
      say "👋 Welcome to AnyCable interactive installer. We'll guide you through the process of installing AnyCable for your Rails application. Buckle up!"
      say ""
    end

    def rpc_implementation
      say "AnyCable connects to your Rails server to communicate with Action Cable channels (via RPC API). Learn more from the docs 👉 #{DOCS_ROOT}/anycable-go/rpc"
      say ""

      answer = RPC_IMPL.index(options[:rpc]) || 99

      until RPC_IMPL[answer.to_i]
        answer = ask "Do you want to use gRPC or HTTP for AnyCable RPC? (1) gRPC, (2) HTTP, (0) None"
      end

      @rpc_impl = RPC_IMPL[answer.to_i]
    end

    def development_method
      answer = DEVELOPMENT_METHODS.index(options[:devenv]) || 99

      say ""

      until DEVELOPMENT_METHODS[answer.to_i]
        answer = ask "Do you want to run AnyCable server (anycable-go) locally or as a Docker container? (1) Local, (2) Docker, (0) Skip"
      end

      @devenv = DEVELOPMENT_METHODS[answer.to_i]

      case @devenv
      when "skip"
        say_status :help, "⚠️  Please, read this guide on how to install AnyCable server 👉 #{DOCS_ROOT}/anycable-go/getting_started", :yellow
      else
        send "install_for_#{@devenv}"
      end
    end

    def devise
      return unless devise?

      inside("config/initializers") do
        template "anycable.rb"
      end

      say_status :info, "✅ config/initializers/anycable.rb with Devise configuration has been added"
    end

    def configs
      inside("config") do
        template "anycable.yml"
      end

      update_cable_yml
    end

    def rubocop_compatibility
      return unless rubocop?

      say_status :info, "🤖 Running static compatibility checks with RuboCop"
      res = run "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' --only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"
      say_status :help, "⚠️  Please, take a look at the icompatibilities above and fix them. See #{DOCS_ROOT}/rails/compatibility" unless res
    end

    def cable_url_info
      say_status :help, "⚠️  If you're using JS client make sure you have " \
                        "`action_cable_meta_tag` or `action_cable_with_jwt_meta_tag` included in your HTML layout"
    end

    def deployment_method
      say_status :info, "🚢  See our deployment guide to learn how to run AnyCable in production 👉 #{DOCS_ROOT}/deployment"

      say_status :info, "Check out AnyCable+, our hosted AnyCable solution: https://plus.anycable.io"
    end

    def finish
      say_status :info, "✅ AnyCable has been configured successfully!"
    end

    private

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

    def devise?
      !!gemfile_lock&.match?(/^\s+devise\b/)
    end

    def local?
      @devenv == "local"
    end

    def grpc?
      @rpc_impl == "grpc"
    end

    def http_rpc?
      @rpc_impl == "http"
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
      say_status :help, "️️⚠️  Docker development configuration could vary", :yellow

      say "Here is an example snippet for Docker Compose:"

      if @rpc_impl == "grpc"
        say <<~YML
          ─────────────────────────────────────────
          # your Rails application service
          rails: &rails
            # ...
            ports:
              - '3000:3000'
            environment: &rails_environment
              # ...
              ANYCABLE_HTTP_BROADCAST_URL: http://ws:8090/_broadcast
            depends_on: &rails_depends_on
              #...
              anycable:
                condition: service_started

          ws:
            image: anycable/anycable-go:1.5
            ports:
              - '8080:8080'
              - '8090'
            environment:
              ANYCABLE_HOST: "0.0.0.0"
              ANYCABLE_BROADCAST_ADAPTER: http
              ANYCABLE_RPC_HOST: anycable:50051
              ANYCABLE_DEBUG: ${ANYCABLE_DEBUG:-true}

          anycable:
            <<: *rails
            command: bundle exec anycable
            environment:
              <<: *rails_environment
              ANYCABLE_RPC_HOST: 0.0.0.0:50051
            ports:
              - '50051'
            depends_on:
              <<: *rails_depends_on
              ws:
                condition: service_started
          ─────────────────────────────────────────
        YML
      else
        say <<~YML
          ─────────────────────────────────────────
          # Your Rails application service
          rails: &rails
            # ...
            ports:
              - '3000:3000'
            environment: &rails_environment
              # ...
              ANYCABLE_HTTP_BROADCAST_URL: http://ws:8090/_broadcast
            depends_on: &rails_depends_on
              #...
              anycable:
                condition: service_started

          ws:
            image: anycable/anycable-go:1.5
            ports:
              - '8080:8080'
            environment:
              ANYCABLE_HOST: "0.0.0.0"
              ANYCABLE_BROADCAST_ADAPTER: http
              ANYCABLE_RPC_HOST: http://rails:3000/_anycable
              ANYCABLE_DEBUG: ${ANYCABLE_DEBUG:-true}
          ─────────────────────────────────────────
        YML
      end
    end

    def install_for_local
      unless file_exists?("bin/anycable-go")
        generate "anycable:bin", "--version #{options[:version]}"
      end
      template_proc_files
      true
    end

    def update_cable_yml
      if file_exists?("config/cable.yml")
        in_root do
          contents = File.read("config/cable.yml")
          # Replace any adapter: x with any_cable unless x == "test"
          new_contents = contents.gsub(/\sadapter:\s*([^$\n]+)/) do |match|
            adapter = Regexp.last_match[1]
            next match if adapter == "test" || adapter.include?("any_cable")

            match.sub(adapter, %(<%= ENV.fetch("ACTION_CABLE_ADAPTER", "any_cable") %>))
          end

          File.write "config/cable.yml", new_contents
        end
      else
        inside("config") do
          template "cable.yml"
        end
      end
    end

    def template_proc_files
      file_name = "Procfile.dev"

      if file_exists?(file_name)
        update_procfile(file_name)
      else
        say_status :help, "💡 We recommend using Overmind to manage multiple processes in development 👉 https://github.com/DarthSim/overmind", :yellow

        return if options[:skip_procfile_dev]

        template file_name
      end
    end

    def update_procfile(file_name)
      in_root do
        contents = File.read(file_name)

        unless http_rpc?
          unless contents.match?(/^anycable:\s/)
            append_file file_name, "anycable: bundle exec anycable\n", force: true
          end
        end
        unless contents.match?(/^ws:\s/)
          append_file file_name, "ws: bin/anycable-go #{anycable_go_options}", force: true
        end
      end
    end

    def anycable_go_options
      opts = ["--port=8080"]
      opts << "--broadcast_adapter=http" unless redis?
      opts << "--rpc_host=http://localhost:3000/_anycable" if http_rpc?
      opts.join(" ")
    end

    def file_exists?(name)
      in_root do
        return File.file?(name)
      end
    end
  end
end
