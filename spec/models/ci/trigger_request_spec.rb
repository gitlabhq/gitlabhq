require 'spec_helper'

describe Ci::TriggerRequest do
  describe 'validation' do
    it 'be invalid if saving a variable' do
      trigger = build(:ci_trigger_request, variables: { TRIGGER_KEY_1: 'TRIGGER_VALUE_1' } )

      expect(trigger.valid?).to be_falsey
    end

    it 'be valid if not saving a variable' do
      trigger = build(:ci_trigger_request)

      expect(trigger.valid?).to be_truthy
    end
  end
end
