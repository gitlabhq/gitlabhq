# frozen_string_literal: true

require 'spec_helper'

describe JiraTrackerData do
  let(:service) { create(:jira_service, active: false, properties: {}) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end
end
