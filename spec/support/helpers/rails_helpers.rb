# frozen_string_literal: true

module RailsHelpers
  def stub_rails_env(env_name)
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new(env_name))
  end
end
