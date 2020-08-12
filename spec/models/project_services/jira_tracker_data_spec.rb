# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraTrackerData do
  let(:service) { build(:jira_service) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'deployment_type' do
    it { is_expected.to define_enum_for(:deployment_type).with_values([:unknown, :server, :cloud]).with_prefix(:deployment) }
  end
end
