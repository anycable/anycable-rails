# frozen_string_literal: true

shared_context "log:info", log: :info do
  before do
    @old_level = Rails.logger.level
    Rails.logger.level = AnyCable.logger.level = :info
  end

  after { Rails.logger.level = AnyCable.logger.level = @old_level }
end
