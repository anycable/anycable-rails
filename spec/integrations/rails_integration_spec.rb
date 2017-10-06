# frozen_string_literal: true

require "spec_helper"
require "action_controller/test_case"

describe "rails integration" do
  context "no built-in ActionCable" do
    include ActionDispatch::Integration::Runner
    include ActionDispatch::IntegrationTest::Behavior

    # Delegates to `Rails.application`.
    def app
      ::Rails.application
    end

    it "responds with not found" do
      expect { get "/cable" }
        .to output(%r{No route matches \[GET\] "/cable"})
        .to_stdout_from_any_process
      expect(response.code).to eq "404"
    end
  end
end
