# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::MergeBase do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }

  subject(:merge_base) { described_class.new(repository, refs) }

  shared_context 'existing refs with a merge base' do
    let(:refs) do
      %w[304d257dcb821665ab5110318fc58a007bd104ed 0031876facac3f2b2702a0e53a26e89939a42209]
    end
  end

  shared_context 'when passing a missing ref' do
    let(:refs) do
      %w[304d257dcb821665ab5110318fc58a007bd104ed aaaa]
    end
  end

  shared_context 'when passing refs that do not have a common ancestor' do
    let(:refs) { ['304d257dcb821665ab5110318fc58a007bd104ed', TestEnv::BRANCH_SHA['orphaned-branch']] }
  end

  describe '#sha' do
    context 'when the refs exist' do
      include_context 'existing refs with a merge base'

      it 'returns the SHA of the merge base' do
        expect(merge_base.sha).not_to be_nil
      end

      it 'memoizes the result' do
        expect(repository).to receive(:merge_base).once.and_call_original

        2.times { merge_base.sha }
      end
    end

    context 'when passing a missing ref' do
      include_context 'when passing a missing ref'

      it 'does not call merge_base on the repository but raises an error' do
        expect(repository).not_to receive(:merge_base)

        expect { merge_base.sha }.to raise_error(Gitlab::Git::ReferenceNotFoundError)
      end
    end

    context 'when the refs do not have a common ancestor' do
      include_context 'when passing refs that do not have a common ancestor'

      it 'returns `nil`' do
        expect(merge_base.sha).to be_nil
      end
    end

    it 'returns a merge base when passing 2 branch names' do
      merge_base = described_class.new(repository, %w[master feature])

      expect(merge_base.sha).to be_present
    end

    it 'returns a merge base when passing a tag name' do
      merge_base = described_class.new(repository, %w[master v1.0.0])

      expect(merge_base.sha).to be_present
    end
  end

  describe '#commit' do
    context 'for existing refs with a merge base' do
      include_context 'existing refs with a merge base'

      it 'finds the commit for the merge base' do
        expect(merge_base.commit).to be_a(Commit)
      end

      it 'only looks up the commit once' do
        expect(repository).to receive(:commit_by).once.and_call_original

        2.times { merge_base.commit }
      end
    end

    context 'when there is no sha' do
      include_context 'when passing refs that do not have a common ancestor'

      it 'does not try to find the commit' do
        expect(repository).not_to receive(:commit_by)

        merge_base.commit
      end
    end
  end

  describe '#unknown_refs' do
    include_context 'when passing a missing ref'

    it 'returns the refs passed that are not part of the repository' do
      expect(merge_base.unknown_refs).to contain_exactly('aaaa')
    end

    it 'only looks up the commits once' do
      expect(merge_base).to receive(:commits_for_refs).once.and_call_original

      2.times { merge_base.unknown_refs }
    end
  end
end
