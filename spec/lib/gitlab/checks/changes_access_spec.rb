# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::ChangesAccess do
  include_context 'changes access checks context'

  subject { changes_access }

  describe '#validate!' do
    shared_examples '#validate!' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'without failed checks' do
        it "doesn't raise an error" do
          expect { subject.validate! }.not_to raise_error
        end

        it 'calls lfs checks' do
          expect_next_instance_of(Gitlab::Checks::LfsCheck) do |instance|
            expect(instance).to receive(:validate!)
          end

          subject.validate!
        end
      end

      context 'when time limit was reached' do
        it 'raises a TimeoutError' do
          logger = Gitlab::Checks::TimedLogger.new(start_time: timeout.ago, timeout: timeout)
          access = described_class.new(changes,
                                       project: project,
                                       user_access: user_access,
                                       protocol: protocol,
                                       logger: logger)

          expect { access.validate! }.to raise_error(Gitlab::Checks::TimedLogger::TimeoutError)
        end
      end
    end

    context 'with batched commits enabled' do
      before do
        stub_feature_flags(changes_batch_commits: true)
      end

      it_behaves_like '#validate!'
    end

    context 'with batched commits disabled' do
      before do
        stub_feature_flags(changes_batch_commits: false)
      end

      it_behaves_like '#validate!'
    end
  end

  describe '#commits' do
    it 'calls #new_commits' do
      expect(project.repository).to receive(:new_commits).and_call_original

      expect(subject.commits).to eq([])
    end

    context 'when changes contain empty revisions' do
      let(:changes) { [{ newrev: newrev }, { newrev: '' }, { newrev: Gitlab::Git::BLANK_SHA }] }
      let(:expected_commit) { instance_double(Commit) }

      it 'returns only commits with non empty revisions' do
        expect(project.repository).to receive(:new_commits).with([newrev], { allow_quarantine: true }) { [expected_commit] }
        expect(subject.commits).to eq([expected_commit])
      end
    end
  end

  describe '#commits_for' do
    let(:new_commits) { [] }
    let(:expected_commits) { [] }

    shared_examples 'a listing of new commits' do
      it 'returns expected commits' do
        expect(subject).to receive(:commits).and_return(new_commits)

        expect(subject.commits_for(newrev)).to eq(expected_commits)
      end
    end

    context 'with no commits' do
      it_behaves_like 'a listing of new commits'
    end

    context 'with unrelated commits' do
      let(:new_commits) { [create_commit('1234', %w[1111 2222])] }

      it_behaves_like 'a listing of new commits'
    end

    context 'with single related commit' do
      let(:new_commits) { [create_commit(newrev, %w[1111 2222])] }
      let(:expected_commits) { new_commits }

      it_behaves_like 'a listing of new commits'
    end

    context 'with single related and unrelated commit' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111 2222]),
          create_commit('abcd', %w[1111 2222])
        ]
      end

      let(:expected_commits) do
        [create_commit(newrev, %w[1111 2222])]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with multiple related commits' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111]),
          create_commit('1111', %w[2222]),
          create_commit('abcd', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[1111]),
          create_commit('1111', %w[2222])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with merge commits' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[1111 2222 3333]),
          create_commit('1111', []),
          create_commit('3333', %w[4444]),
          create_commit('4444', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[1111 2222 3333]),
          create_commit('1111', []),
          create_commit('3333', %w[4444]),
          create_commit('4444', [])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end

    context 'with criss-cross merges' do
      let(:new_commits) do
        [
          create_commit(newrev, %w[a1 b1]),
          create_commit('a1', %w[a2 b2]),
          create_commit('a2', %w[a3 b3]),
          create_commit('a3', %w[c]),
          create_commit('b1', %w[b2 a2]),
          create_commit('b2', %w[b3 a3]),
          create_commit('b3', %w[c]),
          create_commit('c', [])
        ]
      end

      let(:expected_commits) do
        [
          create_commit(newrev, %w[a1 b1]),
          create_commit('a1', %w[a2 b2]),
          create_commit('b1', %w[b2 a2]),
          create_commit('a2', %w[a3 b3]),
          create_commit('b2', %w[b3 a3]),
          create_commit('a3', %w[c]),
          create_commit('b3', %w[c]),
          create_commit('c', [])
        ]
      end

      it_behaves_like 'a listing of new commits'
    end
  end

  def create_commit(id, parent_ids)
    Gitlab::Git::Commit.new(project.repository, {
      id: id,
      parent_ids: parent_ids
    })
  end
end
