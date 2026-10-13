# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTagLink, feature_category: :incident_management do
  describe 'associations' do
    it { is_expected.to belong_to(:timeline_event) }
    it { is_expected.to belong_to(:timeline_event_tag) }
    it { is_expected.to belong_to(:project) }
  end
end
