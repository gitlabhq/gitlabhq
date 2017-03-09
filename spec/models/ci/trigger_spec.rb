require 'spec_helper'

describe Ci::Trigger, models: true do
  let(:project) { create :empty_project }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:owner) }
    it { is_expected.to have_many(:trigger_requests) }
  end

  describe 'before_validation' do
    it 'sets an random token if none provided' do
      trigger = create(:ci_trigger_without_token, project: project)

      expect(trigger.token).not_to be_nil
    end

    it 'does not set an random token if one provided' do
      trigger = create(:ci_trigger, project: project)

      expect(trigger.token).to eq('token')
    end
  end
end
