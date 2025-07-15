# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::ContainingCommitFinder, feature_category: :source_code_management do
  subject(:finder) { described_class.new(repository, sha, params) }

  let_it_be(:project) { create(:project, :small_repo) }
  let_it_be(:repository) { project.repository }
  let_it_be(:sha) { repository.commit.sha }
  let(:params) { {} }

  before_all do
    project.repository.add_tag(project.creator, 'v1.0', sha)
    project.repository.add_tag(project.creator, 'v2.0', sha)

    project.repository.add_branch(project.creator, 'develop', sha)
  end

  describe '#execute' do
    subject(:execute) { finder.execute }

    it 'returns both branches and tags by default' do
      expected_result = [
        { type: 'branch', name: 'develop' },
        { type: 'branch', name: 'master' },
        { type: 'tag', name: 'v1.0' },
        { type: 'tag', name: 'v2.0' }
      ]

      is_expected.to match_array(expected_result)
    end

    it 'calls repository methods with correct parameters' do
      expect(repository).to receive(:branch_names_contains).with(sha, limit: 0).and_call_original
      expect(repository).to receive(:tag_names_contains).with(sha, limit: 0).and_call_original

      execute
    end

    context 'when type is "branch"' do
      let(:params) { { type: 'branch' } }

      it 'returns only branches' do
        expected_result = [
          { type: 'branch', name: 'develop' },
          { type: 'branch', name: 'master' }
        ]
        is_expected.to match_array(expected_result)
      end

      it 'does not call tag_names_contains' do
        expect(repository).to receive(:branch_names_contains).with(sha, limit: 0).and_call_original
        expect(repository).not_to receive(:tag_names_contains)

        execute
      end
    end

    context 'when type is "tag"' do
      let(:params) { { type: 'tag' } }

      it 'returns only tags' do
        expected_result = [
          { type: 'tag', name: 'v1.0' },
          { type: 'tag', name: 'v2.0' }
        ]
        is_expected.to match_array(expected_result)
      end

      it 'does not call branch_names_contains' do
        expect(repository).to receive(:tag_names_contains).with(sha, limit: 0).and_call_original
        expect(repository).not_to receive(:branch_names_contains)

        execute
      end
    end

    describe 'Limit' do
      context 'when limit is lower than number of branches' do
        let(:params) { { limit: 1 } }

        it 'returns only the first branch' do
          expect(repository).to receive(:branch_names_contains).with(sha, limit: 1).and_call_original
          expect(repository).not_to receive(:tag_names_contains)

          expected_result = [
            { type: 'branch', name: 'develop' }
          ]
          is_expected.to match_array(expected_result)
        end
      end

      context 'when limit is equal to the number of branches' do
        let(:params) { { limit: 2 } }

        it 'returns all branches' do
          expect(repository).to receive(:branch_names_contains).with(sha, limit: 2).and_call_original
          expect(repository).not_to receive(:tag_names_contains)

          expected_result = [
            { type: 'branch', name: 'develop' },
            { type: 'branch', name: 'master' }
          ]
          is_expected.to match_array(expected_result)
        end
      end

      context 'when limit is higher than the number of branches' do
        let(:params) { { limit: 3 } }

        it 'returns the first items from combined results' do
          expect(repository).to receive(:branch_names_contains).with(sha, limit: 3).and_call_original
          expect(repository).to receive(:tag_names_contains).with(sha, limit: 1).and_call_original

          expected_result = [
            { type: 'branch', name: 'develop' },
            { type: 'branch', name: 'master' },
            { type: 'tag', name: 'v1.0' }
          ]
          is_expected.to match_array(expected_result)
        end
      end

      context 'when limit covers both branches and tags' do
        let(:params) { { limit: 4 } }

        it 'returns all items' do
          expect(repository).to receive(:branch_names_contains).with(sha, limit: 4).and_call_original
          expect(repository).to receive(:tag_names_contains).with(sha, limit: 2).and_call_original

          expected_result = [
            { type: 'branch', name: 'develop' },
            { type: 'branch', name: 'master' },
            { type: 'tag', name: 'v1.0' },
            { type: 'tag', name: 'v2.0' }
          ]
          is_expected.to match_array(expected_result)
        end
      end

      context 'when limit is higher than the total number of branches and tags' do
        let(:params) { { limit: 50 } }

        it 'returns all items' do
          expect(repository).to receive(:branch_names_contains).with(sha, limit: 50).and_call_original
          expect(repository).to receive(:tag_names_contains).with(sha, limit: 48).and_call_original

          expected_result = [
            { type: 'branch', name: 'develop' },
            { type: 'branch', name: 'master' },
            { type: 'tag', name: 'v1.0' },
            { type: 'tag', name: 'v2.0' }
          ]
          is_expected.to match_array(expected_result)
        end
      end
    end

    context 'when sha is nil' do
      let(:sha) { nil }

      it 'returns empty array' do
        expect(repository).not_to receive(:branch_names_contains)
        expect(repository).not_to receive(:tag_names_contains)

        is_expected.to eq([])
      end
    end
  end
end
