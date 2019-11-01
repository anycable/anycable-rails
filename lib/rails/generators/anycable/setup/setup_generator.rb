# frozen_string_literal: true

module AnyCableRailsGenerators
  # Entry point for interactive installation
  class SetupGenerator < ::Rails::Generators::Base
    namespace "anycable:setup"
    source_root File.expand_path("templates", __dir__)

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
    end

    def development_method
      answer = nil

      until [1, 2, 3].include?(answer.to_i)
        answer = ask "Which environment do you use for development? (1) Local, (2) Docker, (3) Skip"
      end

      env = [nil, "local", "docker"][answer.to_i]

      return if env.nil?

      require "rails/generators/anycable/setup/#{env.underscore}/#{env.underscore}_generator"
      "AnyCableRailsGenerators::Setup::#{env.camelize}Generator".constantize.new.invoke_all
    end

    def heroku
      return unless yes? "Do you use Heroku for deployment?"

      template "Procfile"
      inside("bin") { template "heroku-web" }

      say_status :help, "️️⚠️ Please, read the required steps to configure Heroku applications 👉 https://docs.anycable.io/#/deployment/heroku", :yellow
    end

    def finish
      say_status :info, "✅ AnyCable has been configured successfully!"
    end

    private

    def app_name
      ::Rails.application.class.name.sub(/::Application$/, "").underscore
    end
  end
end
