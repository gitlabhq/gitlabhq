require 'spec_helper'

describe Ci::TriggerRequest do
  describe 'validation' do
    it 'be invalid if saving a variable' do
      trigger = build(:ci_trigger_request, variables: { TRIGGER_KEY_1: 'TRIGGER_VALUE_1' } )

      expect(trigger).not_to be_valid
    end

    it 'be valid if not saving a variable' do
      trigger = build(:ci_trigger_request)

      expect(trigger).to be_valid
    end
  end
end
