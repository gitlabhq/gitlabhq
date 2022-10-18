# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTagLink do
  describe 'associations' do
    it { is_expected.to belong_to(:timeline_event) }
    it { is_expected.to belong_to(:timeline_event_tag) }
  end
end
