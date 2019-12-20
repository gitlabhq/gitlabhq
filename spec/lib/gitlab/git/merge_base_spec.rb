# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Git::MergeBase do
  set(:project) { create(:project, :repository) }
  let(:repository) { project.repository }

  subject(:merge_base) { described_class.new(repository, refs) }

  shared_context 'existing refs with a merge base', :existing_refs do
    let(:refs) do
      %w(304d257dcb821665ab5110318fc58a007bd104ed 0031876facac3f2b2702a0e53a26e89939a42209)
    end
  end

  shared_context 'when passing a missing ref', :missing_ref do
    let(:refs) do
      %w(304d257dcb821665ab5110318fc58a007bd104ed aaaa)
    end
  end

  shared_context 'when passing refs that do not have a common ancestor', :no_common_ancestor do
    let(:refs) { ['304d257dcb821665ab5110318fc58a007bd104ed', TestEnv::BRANCH_SHA['orphaned-branch']] }
  end

  describe '#sha' do
    context 'when the refs exist', :existing_refs do
      it 'returns the SHA of the merge base' do
        expect(merge_base.sha).not_to be_nil
      end

      it 'memoizes the result' do
        expect(repository).to receive(:merge_base).once.and_call_original

        2.times { merge_base.sha }
      end
    end

    context 'when passing a missing ref', :missing_ref do
      it 'does not call merge_base on the repository but raises an error' do
        expect(repository).not_to receive(:merge_base)

        expect { merge_base.sha }.to raise_error(Gitlab::Git::UnknownRef)
      end
    end

    it 'returns `nil` when the refs do not have a common ancestor', :no_common_ancestor do
      expect(merge_base.sha).to be_nil
    end

    it 'returns a merge base when passing 2 branch names' do
      merge_base = described_class.new(repository, %w(master feature))

      expect(merge_base.sha).to be_present
    end

    it 'returns a merge base when passing a tag name' do
      merge_base = described_class.new(repository, %w(master v1.0.0))

      expect(merge_base.sha).to be_present
    end
  end

  describe '#commit' do
    context 'for existing refs with a merge base', :existing_refs do
      it 'finds the commit for the merge base' do
        expect(merge_base.commit).to be_a(Commit)
      end

      it 'only looks up the commit once' do
        expect(repository).to receive(:commit_by).once.and_call_original

        2.times { merge_base.commit }
      end
    end

    it 'does not try to find the commit when there is no sha', :no_common_ancestor do
      expect(repository).not_to receive(:commit_by)

      merge_base.commit
    end
  end

  describe '#unknown_refs', :missing_ref do
    it 'returns the refs passed that are not part of the repository' do
      expect(merge_base.unknown_refs).to contain_exactly('aaaa')
    end

    it 'only looks up the commits once' do
      expect(merge_base).to receive(:commits_for_refs).once.and_call_original

      2.times { merge_base.unknown_refs }
    end
  end
end
