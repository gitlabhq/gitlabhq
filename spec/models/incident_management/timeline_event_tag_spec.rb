# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTag do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:timeline_event_tag_links).class_name('IncidentManagement::TimelineEventTagLink') }

    it {
      is_expected.to have_many(:timeline_events)
      .class_name('IncidentManagement::TimelineEvent').through(:timeline_event_tag_links)
    }
  end

  describe 'validations' do
    subject { build(:incident_management_timeline_event_tag) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:project_id]) }

    it { is_expected.to allow_value('Test tag 1').for(:name) }
    it { is_expected.not_to allow_value('Test tag, 1').for(:name) }
    it { is_expected.not_to allow_value('').for(:name) }
    it { is_expected.not_to allow_value('s' * 256).for(:name) }
  end
end
