require 'spec_helper'

describe PushEvent do
  let(:payload) { PushEventPayload.new }

  let(:event) do
    event = described_class.new

    allow(event).to receive(:push_event_payload).and_return(payload)

    event
  end

  describe '.sti_name' do
    it 'returns Event::PUSHED' do
      expect(described_class.sti_name).to eq(Event::PUSHED)
    end
  end

  describe '#push?' do
    it 'returns true' do
      expect(event).to be_push
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
      event.action = Event::CREATED
      event.validate_push_action

      expect(event.errors.count).to eq(1)
    end
  end
end
