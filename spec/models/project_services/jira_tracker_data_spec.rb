# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraTrackerData do
  let(:service) { create(:jira_service, active: false) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end
end
