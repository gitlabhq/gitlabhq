# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PushEvent do
  let(:payload) { PushEventPayload.new }

  let(:event) do
    event = described_class.new

    allow(event).to receive(:push_event_payload).and_return(payload)

    event
  end

  describe '.created_or_pushed' do
    let(:event1) { create(:push_event) }
    let(:event2) { create(:push_event) }
    let(:event3) { create(:push_event) }

    before do
      create(:push_event_payload, event: event1, action: :pushed)
      create(:push_event_payload, event: event2, action: :created)
      create(:push_event_payload, event: event3, action: :removed)
    end

    let(:relation) { described_class.created_or_pushed }

    it 'includes events for pushing to existing refs' do
      expect(relation).to include(event1)
    end

    it 'includes events for creating new refs' do
      expect(relation).to include(event2)
    end

    it 'does not include events for removing refs' do
      expect(relation).not_to include(event3)
    end
  end

  describe '.branch_events' do
    let(:event1) { create(:push_event) }
    let(:event2) { create(:push_event) }

    before do
      create(:push_event_payload, event: event1, ref_type: :branch)
      create(:push_event_payload, event: event2, ref_type: :tag)
    end

    let(:relation) { described_class.branch_events }

    it 'includes events for branches' do
      expect(relation).to include(event1)
    end

    it 'does not include events for tags' do
      expect(relation).not_to include(event2)
    end
  end

  describe '.without_existing_merge_requests' do
    let(:project) { create(:project, :repository) }
    let(:event1) { create(:push_event, project: project) }
    let(:event2) { create(:push_event, project: project) }
    let(:event3) { create(:push_event, project: project) }
    let(:event4) { create(:push_event, project: project) }
    let(:event5) { create(:push_event, project: project) }

    before do
      create(:push_event_payload, event: event1, ref: 'foo', action: :created)
      create(:push_event_payload, event: event2, ref: 'bar', action: :created)
      create(:push_event_payload, event: event3, ref: 'qux', action: :created)
      create(:push_event_payload, event: event4, ref: 'baz', action: :removed)
      create(:push_event_payload, event: event5, ref: 'baz', ref_type: :tag)

      project.repository.create_branch('bar')

      create(
        :merge_request,
        source_project: project,
        target_project: project,
        source_branch: 'bar'
      )

      project.repository.create_branch('qux')

      create(
        :merge_request,
        :closed,
        source_project: project,
        target_project: project,
        source_branch: 'qux'
      )
    end

    let(:relation) { described_class.without_existing_merge_requests }

    it 'includes events that do not have a corresponding merge request' do
      expect(relation).to include(event1)
    end

    it 'does not include events that have a corresponding open merge request' do
      expect(relation).not_to include(event2)
    end

    it 'includes events that has corresponding closed/merged merge requests' do
      expect(relation).to include(event3)
    end

    it 'does not include events for removed refs' do
      expect(relation).not_to include(event4)
    end

    it 'does not include events for pushing to tags' do
      expect(relation).not_to include(event5)
    end
  end

  describe '.sti_name' do
    it 'returns the integer representation of the :pushed event action' do
      expect(described_class.sti_name).to eq(Event.actions[:pushed])
    end
  end

  describe '#push_action?' do
    it 'returns true' do
      expect(event).to be_push_action
    end
  end

  describe '#push_with_commits?' do
    it 'returns true when both the first and last commit are present' do
      allow(event).to receive(:commit_from).and_return('123')
      allow(event).to receive(:commit_to).and_return('456')

      expect(event).to be_push_with_commits
    end

    it 'returns false when the first commit is missing' do
      allow(event).to receive(:commit_to).and_return('456')

      expect(event).not_to be_push_with_commits
    end

    it 'returns false when the last commit is missing' do
      allow(event).to receive(:commit_from).and_return('123')

      expect(event).not_to be_push_with_commits
    end
  end

  describe '#tag?' do
    it 'returns true when pushing to a tag' do
      allow(payload).to receive(:tag?).and_return(true)

      expect(event).to be_tag
    end

    it 'returns false when pushing to a branch' do
      allow(payload).to receive(:tag?).and_return(false)

      expect(event).not_to be_tag
    end
  end

  describe '#branch?' do
    it 'returns true when pushing to a branch' do
      allow(payload).to receive(:branch?).and_return(true)

      expect(event).to be_branch
    end

    it 'returns false when pushing to a tag' do
      allow(payload).to receive(:branch?).and_return(false)

      expect(event).not_to be_branch
    end
  end

  describe '#valid_push?' do
    it 'returns true if a ref exists' do
      allow(payload).to receive(:ref).and_return('master')

      expect(event).to be_valid_push
    end

    it 'returns false when no ref is present' do
      expect(event).not_to be_valid_push
    end
  end

  describe '#new_ref?' do
    it 'returns true when pushing a new ref' do
      allow(payload).to receive(:created?).and_return(true)

      expect(event).to be_new_ref
    end

    it 'returns false when pushing to an existing ref' do
      allow(payload).to receive(:created?).and_return(false)

      expect(event).not_to be_new_ref
    end
  end

  describe '#rm_ref?' do
    it 'returns true when removing an existing ref' do
      allow(payload).to receive(:removed?).and_return(true)

      expect(event).to be_rm_ref
    end

    it 'returns false when pushing to an existing ref' do
      allow(payload).to receive(:removed?).and_return(false)

      expect(event).not_to be_rm_ref
    end
  end

  describe '#commit_from' do
    it 'returns the first commit SHA' do
      allow(payload).to receive(:commit_from).and_return('123')

      expect(event.commit_from).to eq('123')
    end
  end

  describe '#commit_to' do
    it 'returns the last commit SHA' do
      allow(payload).to receive(:commit_to).and_return('123')

      expect(event.commit_to).to eq('123')
    end
  end

  describe '#ref_name' do
    it 'returns the name of the ref' do
      allow(payload).to receive(:ref).and_return('master')

      expect(event.ref_name).to eq('master')
    end
  end

  describe '#ref_type' do
    it 'returns the type of the ref' do
      allow(payload).to receive(:ref_type).and_return('branch')

      expect(event.ref_type).to eq('branch')
    end
  end

  describe '#branch_name' do
    it 'returns the name of the branch' do
      allow(payload).to receive(:ref).and_return('master')

      expect(event.branch_name).to eq('master')
    end
  end

  describe '#tag_name' do
    it 'returns the name of the tag' do
      allow(payload).to receive(:ref).and_return('1.2')

      expect(event.tag_name).to eq('1.2')
    end
  end

  describe '#commit_title' do
    it 'returns the commit message' do
      allow(payload).to receive(:commit_title).and_return('foo')

      expect(event.commit_title).to eq('foo')
    end
  end

  describe '#commit_id' do
    it 'returns the SHA of the last commit if present' do
      allow(event).to receive(:commit_to).and_return('123')

      expect(event.commit_id).to eq('123')
    end

    it 'returns the SHA of the first commit if the last commit is not present' do
      allow(event).to receive(:commit_to).and_return(nil)
      allow(event).to receive(:commit_from).and_return('123')

      expect(event.commit_id).to eq('123')
    end
  end

  describe '#commits_count' do
    it 'returns the number of commits' do
      allow(payload).to receive(:commit_count).and_return(1)

      expect(event.commits_count).to eq(1)
    end
  end

  describe '#validate_push_action' do
    it 'adds an error when the action is not PUSHED' do
      event.action = :created
      event.validate_push_action

      expect(event.errors.count).to eq(1)
    end
  end
end
