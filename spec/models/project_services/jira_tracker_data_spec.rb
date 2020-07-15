# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraTrackerData do
  let(:service) { build(:jira_service) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end
end
