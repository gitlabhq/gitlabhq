# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceLabelEvent, type: :model do
  subject { build(:resource_label_event, issue: issue) }

  let(:issue) { create(:issue) }
  let(:merge_request) { create(:merge_request) }

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:merge_request) }
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
end
