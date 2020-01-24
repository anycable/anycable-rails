# frozen_string_literal: true

require "base_spec_helper"

require "open3"

describe "Rubocop default config" do
  def run_rubocop(path)
    cops_path = File.expand_path("lib/anycable/rails/compatibility/rubocop.rb", PROJECT_ROOT)
    output, _status = Open3.capture2(
      "bundle exec rubocop --force-default-config -d -r #{cops_path} #{path}",
      chdir: File.join(__dir__, "fixtures")
    )
    output
  end

  it "should trigger inside channels directory" do
    res = run_rubocop("app/channels/bad_channel.rb")

    expect(res).to include("Inspecting 1 file")
    expect(res).to include("4 offenses detected")
    expect(res).to include("AnyCable/InstanceVars")
    expect(res).to include("@another_var")
    expect(res).to include("@bad_var")
    expect(res).to include("AnyCable/StreamFrom")
    expect(res).to include("AnyCable/PeriodicalTimers")
  end

  it "should not trigger inside controllers directory" do
    res = run_rubocop("app/controllers/good_controller.rb")

    expect(res).to include("Inspecting 1 file")
    expect(res).to include("1 offense detected")
    expect(res).to include("AnyCable/RemoteDisconnect")
  end
end
