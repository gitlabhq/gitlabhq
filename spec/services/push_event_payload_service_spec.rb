# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PushEventPayloadService, feature_category: :source_code_management do
  let(:event) { create(:push_event) }

  describe '#execute' do
    let(:push_data) do
      {
        commits: [
          {
            id: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
            message: 'This is a commit'
          }
        ],
        before: '0000000000000000000000000000000000000000',
        after: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
        total_commits_count: 1,
        ref: 'refs/heads/my-branch'
      }
    end

    it 'creates a new PushEventPayload row' do
      payload = described_class.new(event, push_data).execute

      expect(payload.commit_count).to eq(1)
      expect(payload.action).to eq('created')
      expect(payload.ref_type).to eq('branch')
      expect(payload.commit_from).to be_nil
      expect(payload.commit_to).to eq(push_data[:after])
      expect(payload.ref).to eq('my-branch')
      expect(payload.commit_title).to eq('This is a commit')
      expect(payload.event_id).to eq(event.id)
    end

    it 'sets the push_event_payload association of the used event' do
      payload = described_class.new(event, push_data).execute

      expect(event.push_event_payload).to eq(payload)
    end
  end

  describe '#commit_title' do
    it 'returns nil if no commits were pushed' do
      service = described_class.new(event, commits: [])

      expect(service.commit_title).to be_nil
    end

    it 'returns a String limited to 70 characters' do
      service = described_class.new(event, commits: [{ message: 'a' * 100 }])

      expect(service.commit_title).to eq(('a' * 67) + '...')
    end

    it 'does not truncate the commit message if it is shorter than 70 characters' do
      service = described_class.new(event, commits: [{ message: 'Hello' }])

      expect(service.commit_title).to eq('Hello')
    end

    it 'includes the first line of a commit message if the message spans multiple lines' do
      service = described_class
        .new(event, commits: [{ message: "Hello\n\nworld" }])

      expect(service.commit_title).to eq('Hello')
    end
  end

  describe '#commit_from_id' do
    it 'returns nil when creating a new ref' do
      service = described_class.new(event, before: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.commit_from_id).to be_nil
    end

    it 'returns the ID of the first commit when pushing to an existing ref' do
      service = described_class.new(event, before: '123')

      expect(service.commit_from_id).to eq('123')
    end
  end

  describe '#commit_to_id' do
    it 'returns nil when removing an existing ref' do
      service = described_class.new(event, after: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.commit_to_id).to be_nil
    end
  end

  describe '#commit_count' do
    it 'returns the number of commits' do
      service = described_class.new(event, total_commits_count: 1)

      expect(service.commit_count).to eq(1)
    end

    it 'raises when the push data does not contain the commits count' do
      service = described_class.new(event, {})

      expect { service.commit_count }.to raise_error(KeyError)
    end
  end

  describe '#ref' do
    it 'returns the name of the ref' do
      service = described_class.new(event, ref: 'refs/heads/foo')

      expect(service.ref).to eq('refs/heads/foo')
    end

    it 'raises when the push data does not contain the ref name' do
      service = described_class.new(event, {})

      expect { service.ref }.to raise_error(KeyError)
    end
  end

  describe '#revision_before' do
    it 'returns the revision from before the push' do
      service = described_class.new(event, before: 'foo')

      expect(service.revision_before).to eq('foo')
    end

    it 'raises when the push data does not contain the before revision' do
      service = described_class.new(event, {})

      expect { service.revision_before }.to raise_error(KeyError)
    end
  end

  describe '#revision_after' do
    it 'returns the revision from after the push' do
      service = described_class.new(event, after: 'foo')

      expect(service.revision_after).to eq('foo')
    end

    it 'raises when the push data does not contain the after revision' do
      service = described_class.new(event, {})

      expect { service.revision_after }.to raise_error(KeyError)
    end
  end

  describe '#trimmed_ref' do
    it 'returns the ref name without its prefix' do
      service = described_class.new(event, ref: 'refs/heads/foo')

      expect(service.trimmed_ref).to eq('foo')
    end
  end

  describe '#create?' do
    it 'returns true when creating a new ref' do
      service = described_class.new(event, before: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.create?).to eq(true)
    end

    it 'returns false when pushing to an existing ref' do
      service = described_class.new(event, before: 'foo')

      expect(service.create?).to eq(false)
    end
  end

  describe '#remove?' do
    it 'returns true when removing an existing ref' do
      service = described_class.new(event, after: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.remove?).to eq(true)
    end

    it 'returns false pushing to an existing ref' do
      service = described_class.new(event, after: 'foo')

      expect(service.remove?).to eq(false)
    end
  end

  describe '#action' do
    it 'returns :created when creating a ref' do
      service = described_class.new(event, before: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.action).to eq(:created)
    end

    it 'returns :removed when removing an existing ref' do
      service = described_class.new(event, before: '123', after: Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.action).to eq(:removed)
    end

    it 'returns :pushed when pushing to an existing ref' do
      service = described_class.new(event, before: '123', after: '456')

      expect(service.action).to eq(:pushed)
    end
  end

  describe '#ref_type' do
    it 'returns :tag for a tag' do
      service = described_class.new(event, ref: 'refs/tags/1.2')

      expect(service.ref_type).to eq(:tag)
    end

    it 'returns :branch for a branch' do
      service = described_class.new(event, ref: 'refs/heads/master')

      expect(service.ref_type).to eq(:branch)
    end
  end
end
