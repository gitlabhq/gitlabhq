# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerRequest, feature_category: :continuous_integration do
  describe 'validation' do
    it { is_expected.to validate_presence_of(:project_id) }

    it 'be invalid if saving a variable' do
      trigger = build(:ci_trigger_request, variables: { TRIGGER_KEY_1: 'TRIGGER_VALUE_1' }, project_id: 1)

      expect(trigger).not_to be_valid
    end

    it 'be valid if not saving a variable' do
      trigger = build(:ci_trigger_request, project_id: 1)

      expect(trigger).to be_valid
    end
  end
end
