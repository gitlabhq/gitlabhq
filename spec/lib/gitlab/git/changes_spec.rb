# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Git::Changes do
  let(:changes) { described_class.new }

  describe '#includes_branches?' do
    subject { changes.includes_branches? }

    context 'has changes for branches' do
      before do
        changes.add_branch_change(oldrev: 'abc123', newrev: 'def456', ref: 'branch')
      end

      it { is_expected.to be_truthy }
    end

    context 'has no changes for branches' do
      before do
        changes.add_tag_change(oldrev: 'abc123', newrev: 'def456', ref: 'tag')
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#includes_tags?' do
    subject { changes.includes_tags? }

    context 'has changes for tags' do
      before do
        changes.add_tag_change(oldrev: 'abc123', newrev: 'def456', ref: 'tag')
      end

      it { is_expected.to be_truthy }
    end

    context 'has no changes for tags' do
      before do
        changes.add_branch_change(oldrev: 'abc123', newrev: 'def456', ref: 'branch')
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#add_branch_change' do
    let(:change) { { oldrev: 'abc123', newrev: 'def456', ref: 'branch' } }

    subject { changes.add_branch_change(change) }

    it 'adds the branch change to the collection' do
      expect(subject).to include(change)
      expect(subject.refs).to include(change[:ref])
      expect(subject.repository_data).to include(before: change[:oldrev], after: change[:newrev], ref: change[:ref])
      expect(subject.branch_changes).to include(change)
    end

    it 'does not add the change as a tag change' do
      expect(subject.tag_changes).not_to include(change)
    end
  end

  describe '#add_tag_change' do
    let(:change) { { oldrev: 'abc123', newrev: 'def456', ref: 'tag' } }

    subject { changes.add_tag_change(change) }

    it 'adds the tag change to the collection' do
      expect(subject).to include(change)
      expect(subject.refs).to include(change[:ref])
      expect(subject.repository_data).to include(before: change[:oldrev], after: change[:newrev], ref: change[:ref])
      expect(subject.tag_changes).to include(change)
    end

    it 'does not add the change as a branch change' do
      expect(subject.branch_changes).not_to include(change)
    end
  end
end
