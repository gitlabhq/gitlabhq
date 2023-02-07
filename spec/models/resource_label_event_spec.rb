# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceLabelEvent, feature_category: :team_planning, type: :model do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:label) { create(:label, project: project) }

  subject { build(:resource_label_event, issue: issue, label: label) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
  it_behaves_like 'a note for work item resource event'

  describe 'associations' do
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    describe 'Issuable validation' do
      it 'is invalid if issue_id and merge_request_id are missing' do
        subject.attributes = { issue: nil, merge_request: nil }

        expect(subject).to be_invalid
      end

      it 'is invalid if issue_id and merge_request_id are set' do
        subject.attributes = { issue: issue, merge_request: merge_request }

        expect(subject).to be_invalid
      end

      it 'is valid if only issue_id is set' do
        subject.attributes = { issue: issue, merge_request: nil }

        expect(subject).to be_valid
      end

      it 'is valid if only merge_request_id is set' do
        subject.attributes = { merge_request: merge_request, issue: nil }

        expect(subject).to be_valid
      end
    end
  end

  context 'callbacks' do
    describe '#expire_etag_cache' do
      def expect_expiration(issue)
        expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
          expect(instance).to receive(:touch)
            .with("/#{issue.project.namespace.to_param}/#{issue.project.to_param}/noteable/issue/#{issue.id}/notes")
        end
      end

      it 'expires resource note etag cache on event save' do
        expect_expiration(subject.issuable)

        subject.save!
      end

      it 'expires resource note etag cache on event destroy' do
        subject.save!

        expect_expiration(subject.issuable)

        subject.destroy!
      end
    end
  end

  describe '#outdated_markdown?' do
    it 'returns true if label is missing and reference is not empty' do
      subject.attributes = { reference: 'ref', label_id: nil }

      expect(subject.outdated_markdown?).to be true
    end

    it 'returns true if reference is not set yet' do
      subject.attributes = { reference: nil }

      expect(subject.outdated_markdown?).to be true
    end

    it 'returns true if markdown is outdated' do
      subject.attributes = { cached_markdown_version: ((Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION - 1) << 16) | 0 }

      expect(subject.outdated_markdown?).to be true
    end

    it 'returns false if label and reference are set' do
      subject.attributes = { reference: 'whatever', cached_markdown_version: Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION << 16 }

      expect(subject.outdated_markdown?).to be false
    end
  end

  describe '.visible_to_user?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:issue_project) { create(:project) }
    let_it_be(:issue) { create(:issue, project: issue_project) }

    subject { described_class.visible_to_user?(user, issue.resource_label_events.inc_relations) }

    it 'returns events with labels accessible by user' do
      label = create(:label, project: issue_project)
      event = create_event(label)
      issue_project.add_guest(user)

      expect(subject).to eq [event]
    end

    it 'filters events with public project labels if issues and MRs are private' do
      project = create(:project, :public, :issues_private, :merge_requests_private)
      label = create(:label, project: project)
      create_event(label)

      expect(subject).to be_empty
    end

    it 'filters events with project labels not accessible by user' do
      project = create(:project, :private)
      label = create(:label, project: project)
      create_event(label)

      expect(subject).to be_empty
    end

    it 'filters events with group labels not accessible by user' do
      group = create(:group, :private)
      label = create(:group_label, group: group)
      create_event(label)

      expect(subject).to be_empty
    end

    def create_event(label)
      create(:resource_label_event, issue: issue, label: label)
    end
  end

  describe '#discussion_id' do
    it 'generates different discussion ID for events created milliseconds apart' do
      now = Time.current
      event_1 = create(:resource_label_event, issue: issue, label: label, user: issue.author, created_at: now)
      event_2 = create(:resource_label_event, issue: issue, label: label, user: issue.author, created_at: now.advance(seconds: 0.001))

      expect(event_1.discussion_id).not_to eq(event_2.discussion_id)
    end
  end

  context 'with multiple label events' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, :task, project: project, author: user) }
    let_it_be(:events) { create_pair(:resource_label_event, issue: work_item) }

    it 'builds synthetic note' do
      first_event = events.first
      synthetic_note = first_event.work_item_synthetic_system_note(events: events)

      expect(synthetic_note.class.name).to eq(first_event.synthetic_note_class.name)
      expect(synthetic_note.events).to match_array(events)
    end
  end
end
