# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueTrackerData do
  let(:service) { create(:custom_issue_tracker_service, active: false, properties: {}) }

  describe 'Associations' do
    it { is_expected.to belong_to :service }
  end
end
