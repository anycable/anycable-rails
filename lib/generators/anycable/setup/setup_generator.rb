# frozen_string_literal: true

require "generators/anycable/with_os_helpers"

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

    DOCS_ROOT = "https://docs.anycable.io"
    DEVELOPMENT_METHODS = %w[skip local docker].freeze
    DEPLOYMENT_METHODS = %w[skip thruster fly heroku anycable_plus].freeze
    RPC_IMPL = %w[none grpc http].freeze

    class_option :development,
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
      @todos = []
    end

    def rpc_implementation
      if RPC_IMPL.include?(options[:rpc])
        @rpc_impl = options[:rpc]
        return
      end

      if hotwire? && !custom_channels?
        say <<~MSG
          ⚡️ Hotwire application has been detected, installing AnyCable in a standalone mode.
        MSG
        @rpc_impl = "none"
        return
      end

      if custom_channels?
        answer = RPC_IMPL.index(options[:rpc]) || 99

        unless RPC_IMPL[answer.to_i]
          say <<~MSG
            AnyCable connects to your Rails server to communicate with Action Cable channels either via HTTP or gRPC.

            gRPC provides better performance and scalability but requires running
            a separate component (a gRPC server).

            HTTP is a good option for a quick start or in case your deployment platform doesn't
            support running multiple web services (e.g., Heroku).

            If you only use Action Cable for Turbo Streams, you don't need RPC at all.

            Learn more from the docs 👉 #{DOCS_ROOT}/anycable-go/rpc
          MSG
          say ""
        end

        until RPC_IMPL[answer.to_i]
          answer = ask "Which RPC implementation would you like to use? (1) gRPC, (2) HTTP, (0) None"
        end

        @rpc_impl = RPC_IMPL[answer.to_i]
      end

      # no Hotwire, no custom channels
      say "Looks like you don't have any real-time functionality yet. Let's start with a miminal AnyCable setup!"
      @rpc_impl = "none"
    end

    def development_method
      if DEVELOPMENT_METHODS.include?(options[:development])
        @development = options[:development]
      end

      # Fast-track for local development
      if file_exists?("bin/dev") && file_exists?("Procfile.dev")
        @development = "local"
      end

      unless @development
        say <<~MSG
          You can run AnyCable server locally (recommended for most cases) or as a Docker container (in case you develop in a containerized environment).

          For a local installation, we provide a convenient binstub (`bin/anycable-go`) which automatically
          installs AnyCable server for the current platform.
        MSG
        say ""

        answer = DEVELOPMENT_METHODS.index(options[:development]) || 99

        until DEVELOPMENT_METHODS[answer.to_i]
          answer = ask <<~MSG
            Which way to run AnyCable server locally would you prefer? (1) Binstub, (2) Docker, (0) Skip
          MSG
        end

        @development = DEVELOPMENT_METHODS[answer.to_i]
      end

      case @development
      when "skip"
        @todos << "Install AnyCable server for local development: #{DOCS_ROOT}/anycable-go/getting_started"
      else
        send "install_for_#{@development}"
      end
    end

    def configs
      inside("config") do
        template "anycable.yml"
      end

      template "anycable.toml"

      update_cable_yml
    end

    def rubocop_compatibility
      return unless rubocop?

      say_status :info, "🤖 Running static compatibility checks with RuboCop"
      res = run "bundle exec rubocop -r 'anycable/rails/compatibility/rubocop' --only AnyCable/InstanceVars,AnyCable/PeriodicalTimers,AnyCable/InstanceVars"

      unless res
        say_status :help, "⚠️  Please, take a look at the icompatibilities above and fix them"

        @todos << "Fix Action Cable compatibility issues (listed above): #{DOCS_ROOT}/rails/compatibility"
      end
    end

    def cable_url_info
      meta_tag = norpc? ? "action_cable_with_jwt_meta_tag" : "action_cable_meta_tag"

      begin
        app_layout = nil
        inside("app/views/layouts") do
          next unless File.file?("application.html.erb")
          app_layout = File.read("application.html.erb")
        end
        return if app_layout&.include?(meta_tag)

        if norpc? && app_layout&.include?("action_cable_meta_tag")
          gsub_file "app/views/layouts/application.html.erb", %r{^\s+<%= action_cable_meta_tag %>.*$} do |match|
            match.sub("action_cable_meta_tag", "action_cable_with_jwt_meta_tag")
          end
          inform_jwt_identifiers("app/views/layouts/application.html.erb")
          return
        end

        found = false
        gsub_file "app/views/layouts/application.html.erb", %r{^\s+<%= csp_meta_tag %>.*$} do |match|
          found = true
          match << "\n    <%= #{meta_tag} %>"
        end
        if found
          inform_jwt_identifiers("app/views/layouts/application.html.erb") if norpc?
          return
        end
      rescue Errno::ENOENT
      end

      @todos << "⚠️  Ensure you have `action_cable_meta_tag`\n" \
        "      or `action_cable_with_jwt_meta_tag` included in your HTML layout:\n" \
        "      👉 https://docs.anycable.io/rails/getting_started"
    end

    def action_cable_engine
      return unless application_rb
      return if application_rb.match?(/^require\s+['"](action_cable\/engine|rails\/all)['"]/)

      found = false
      gsub_file "config/application.rb", %r{^require ['"]rails['"].*$} do |match|
        found = true
        match << %(\nrequire "action_cable/engine")
      end

      return if found

      @todos << "⚠️  Ensure Action Cable is loaded. Add `require \"action_cable/engine\"` to your `config/application.rb` file"
    end

    def anycable_client
      if hotwire? && install_js_packages
        gsub_file "app/javascript/application.js", /^import "@hotwired\/turbo-rails".*$/, <<~JS
          import "@hotwired/turbo"
          import { createCable } from "@anycable/web"
          import { start } from "@anycable/turbo-stream"

          // Use extended Action Cable protocol to support reliable streams and presence
          // See https://github.com/anycable/anycable-client
          const cable = createCable({ protocol: 'actioncable-v1-ext-json' })
          // Prevent frequent resubscriptions during morphing or navigation
          start(cable, { delayedUnsubscribe: true })
        JS
        return
      end

      @todos << "⚠️  Install AnyCable JS client to use advanced features (presence, reliable streams): 👉 https://github.com/anycable/anycable-client\n"
    end

    def turbo_verifier_key
      return unless hotwire?
      return if application_rb.include?("config.turbo.signed_stream_verifier_key = AnyCable.config.secret")

      gsub_file "config/application.rb", %r{\s+end\nend} do |match|
        "\n\n" \
        "    # Use AnyCable secret to sign Turbo Streams\n" \
        "    # #{DOCS_ROOT}/guides/hotwire?id=rails-applications\n" \
        "    config.turbo.signed_stream_verifier_key = AnyCable.config.secret#{match}"
      end
    end

    def deployment_method
      @todos << "🚢 Learn how to run AnyCable in production: 👉 #{DOCS_ROOT}/deployment\n" \
        "      For the quick start, consider using AnyCable+ (https://plus.anycable.io)\n" \
        "      or AnyCable Thruster (https://github.com/anycable/thruster)"
    end

    def finish
      say_status :info, "✅ AnyCable has been configured"

      if @todos.any?
        say ""
        say "📋 Please, check the following actions required to complete the setup:\n"
        @todos.each do |todo|
          say "- [ ] #{todo}"
        end
      end
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

    def local?
      @development == "local"
    end

    def grpc?
      @rpc_impl == "grpc"
    end

    def http_rpc?
      @rpc_impl == "http"
    end

    def norpc?
      @rpc_impl == "none"
    end

    def hotwire?
      !!gemfile_lock&.match?(/^\s+turbo-rails\b/) &&
        application_js&.match?(/^import\s+"@hotwired\/turbo/)
    end

    def custom_channels?
      @has_custom_channels ||= begin
        res = nil
        in_root do
          next unless File.directory?("app/channels")
          res = Dir["app/channels/*_channel.rb"].any?
        end
        res
      end
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

    def application_rb
      @application_rb ||= begin
        res = nil
        in_root do
          next unless File.file?("config/application.rb")
          res = File.read("config/application.rb")
        end
        res
      end
    end

    def application_js
      @application_js ||= begin
        res = nil
        in_root do
          next unless File.file?("app/javascript/application.js")
          res = File.read("app/javascript/application.js")
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
            image: anycable/anycable-go:1.6
            ports:
              - '8080:8080'
              - '8090'
            environment:
              ANYCABLE_HOST: "0.0.0.0"
              ANYCABLE_BROADCAST_ADAPTER: http
              ANYCABLE_RPC_HOST: anycable:50051
              ANYCABLE_DEBUG: ${ANYCABLE_DEBUG:-true}
              ANYCABLE_SECRET: "anycable-local-secret"

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
              ANYCABLE_SECRET: "anycable-local-secret"
          ─────────────────────────────────────────
        YML
      end
    end

    def install_for_local
      unless file_exists?("bin/anycable-go")
        generate "anycable:bin", "--version #{options[:version]}"
      end
      template_proc_files
      update_bin_dev
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

            match.sub(adapter, "any_cable")
          end

          # Try removing all lines contaning options for previous adapters,
          # only keep aliases (<<:*), adapter and channel_prefix options.
          new_clean_contents = new_contents.lines.select do |line|
            line.match?(/^(\S|\s+adapter:|\s+channel_prefix:|\s+<<:)/) || line.match?(/^\s*$/)
          end.join

          # Verify new config
          begin
            clean_config = YAML.safe_load(new_clean_contents, aliases: true).deep_symbolize_keys
            orig_config = YAML.safe_load(contents, aliases: true).deep_symbolize_keys

            new_contents = new_clean_contents if clean_config.keys == orig_config.keys
          rescue => _e
            # something went wrong, keep older options
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
        return if options[:skip_procfile_dev]

        template file_name
      end
    end

    def update_procfile(file_name)
      in_root do
        contents = File.read(file_name)

        if grpc?
          unless contents.match?(/^anycable:\s/)
            append_file file_name, "anycable: bundle exec anycable\n", force: true
          end
        end
        unless contents.match?(/^ws:\s/)
          append_file file_name, "ws: bin/anycable-go --port 8080", force: true
        end
      end
    end

    def update_bin_dev
      unless file_exists?("bin/dev")
        template "bin/dev"
        chmod "bin/dev", 0755, verbose: false # rubocop:disable Style/NumericLiteralPrefix

        @todos << "Now you should use bin/dev to run your application with AnyCable services"
        return
      end

      in_root do
        contents = File.read("bin/dev")

        return if contents.include?("Procfile.dev")

        if contents.include?(%(exec "./bin/rails"))
          template "bin/dev", force: true
          chmod "bin/dev", 0755, verbose: false # rubocop:disable Style/NumericLiteralPrefix
        else
          @todos << "Please, check your bin/dev file and ensure it runs Procfile.dev with AnyCable services"
        end
      end
    end

    def file_exists?(name)
      in_root do
        return File.file?(name)
      end
    end

    def inform_jwt_identifiers(path)
      return unless file_exists?("app/channels/application_cable/connection.rb")

      in_root do
        contents = File.read("app/channels/application_cable/connection.rb")

        if contents.match?(%r{^\s+identified_by\s})
          @todos << "⚠️  Please, provide the correct connection identifiers to the #action_cable_with_jwt_meta_tag in #{path}. Read more: 👉 #{DOCS_ROOT}/rails/authentication?id=jwt-authentication"
        end
      end
    end

    def install_js_packages
      if file_exists?("config/importmap.rb") && file_exists?("bin/importmap")
        run "bin/importmap pin @hotwired/turbo @anycable/web @anycable/turbo-stream"
        true
      elsif file_exists?("yarn.lock")
        run "yarn add @anycable/web @anycable/turbo-stream"
        true
      elsif file_exists?("package-json.lock")
        run "npm install @anycable/web @anycable/turbo-stream"
        true
      else
        false
      end
    rescue => e
      say_status :warn, "Failed to install JS packages: #{e.message}. Skipping..."
      false
    end
  end
end
