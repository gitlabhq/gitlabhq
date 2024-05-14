# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EarlyAccessProgram::TrackingEvent, feature_category: :user_profile do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it do
      is_expected.to validate_inclusion_of(:event_name)
        .in_array(EarlyAccessProgram::TrackingEvent::EVENT_NAME_ALLOWLIST)
    end
  end
end
