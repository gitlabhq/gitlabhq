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
    it { is_expected.to validate_uniqueness_of(:name).scoped_to([:project_id]).ignoring_case_sensitivity }

    it { is_expected.to allow_value('Test tag 1').for(:name) }
    it { is_expected.not_to allow_value('Test tag, 1').for(:name) }
    it { is_expected.not_to allow_value('').for(:name) }
    it { is_expected.not_to allow_value('s' * 256).for(:name) }
  end

  describe '.pluck_names' do
    it 'returns the names of the tags' do
      tag1 = create(:incident_management_timeline_event_tag)
      tag2 = create(:incident_management_timeline_event_tag)

      expect(described_class.pluck_names).to contain_exactly(tag1.name, tag2.name)
    end
  end

  describe 'constants' do
    it 'contains predefined tags' do
      expect(described_class::PREDEFINED_TAGS).to contain_exactly(
        'Start time',
        'End time',
        'Impact detected',
        'Response initiated',
        'Impact mitigated',
        'Cause identified'
      )
    end
  end

  describe '#by_names scope' do
    let_it_be(:project) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:tag1) { create(:incident_management_timeline_event_tag, name: 'Test tag 1', project: project) }
    let_it_be(:tag2) { create(:incident_management_timeline_event_tag, name: 'Test tag 2', project: project) }
    let_it_be(:tag3) { create(:incident_management_timeline_event_tag, name: 'Test tag 3', project: project2) }

    it 'returns two matching tags' do
      expect(described_class.by_names(['Test tag 1', 'Test tag 2'])).to contain_exactly(tag1, tag2)
    end

    it 'returns tags on the project' do
      expect(project2.incident_management_timeline_event_tags.by_names(['Test tag 1',
                                                                        'Test tag 3'])).to contain_exactly(tag3)
    end

    it 'returns one matching tag with case insensitive' do
      expect(described_class.by_names(['tESt tAg 2'])).to contain_exactly(tag2)
    end
  end
end
