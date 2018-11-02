# frozen_string_literal: true

require "open3"

RSpec.describe "Rubocop default config" do
  def run_rubocop(path)
    md_path = File.expand_path("../../lib/anycable/rails/compatibility/cops.rb", __dir__)
    output, _status = Open3.capture2(
      "bundle exec rubocop -d -r #{md_path} #{path}",
      chdir: File.join(__dir__, "fixtures")
    )
    output
  end

  it "should trigger inside channels directory" do
    res = run_rubocop("app/channels/bad_channel.rb")

    expect(res).to include("Inspecting 1 file")
    expect(res).to include("1 offense detected")
    expect(res).to include("Anycable/InstanceVars")
  end

  it "should not trigger inside controllers directory" do
    res = run_rubocop("app/controllers/good_controller.rb")

    expect(res).to include("Inspecting 1 file")
    expect(res).to include("no offenses detected")
  end
end
