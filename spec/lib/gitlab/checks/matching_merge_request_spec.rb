# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::MatchingMergeRequest do
  describe '#match?' do
    let_it_be(:newrev) { '012345678' }
    let_it_be(:target_branch) { 'feature' }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:locked_merge_request) do
      create(:merge_request,
        :locked,
        source_project: project,
        target_project: project,
        target_branch: target_branch,
        in_progress_merge_commit_sha: newrev)
    end

    subject { described_class.new(newrev, target_branch, project) }

    let(:total_counter) { subject.send(:total_counter) }
    let(:stale_counter) { subject.send(:stale_counter) }

    it 'matches a merge request' do
      expect(subject.match?).to be true
    end

    it 'does not match any merge request' do
      matcher = described_class.new(newrev, 'test', project)

      expect(matcher.match?).to be false
    end

    context 'with load balancing enabled' do
      let(:session) { ::Gitlab::Database::LoadBalancing::Session.current }
      let(:all_caught_up) { true }

      before do
        Gitlab::Database::LoadBalancing::Session.clear_session

        allow(::ApplicationRecord.sticking)
          .to receive(:all_caught_up?)
          .and_return(all_caught_up)

        expect(::ApplicationRecord.sticking)
          .to receive(:select_valid_host)
          .with(:project, project.id)
          .and_call_original

        allow(::ApplicationRecord.sticking)
          .to receive(:select_caught_up_replicas)
          .with(:project, project.id)
          .and_return(all_caught_up)
      end

      after do
        Gitlab::Database::LoadBalancing::Session.clear_session
      end

      shared_examples 'secondary that has caught up to a primary' do
        it 'continues to use the secondary' do
          expect(session.use_primary?).to be false
          expect(subject.match?).to be true
        end

        it 'only increments total counter' do
          expect { subject.match? }
            .to change { total_counter.get }.by(1)
            .and change { stale_counter.get }.by(0)
        end
      end

      shared_examples 'secondary that is lagging primary' do
        it 'sticks to the primary' do
          expect(subject.match?).to be true
          expect(session.use_primary?).to be true
        end

        it 'increments both total and stale counters' do
          expect { subject.match? }
            .to change { total_counter.get }.by(1)
            .and change { stale_counter.get }.by(1)
        end
      end

      it_behaves_like 'secondary that has caught up to a primary'

      context 'on secondary behind primary' do
        let(:all_caught_up) { false }

        it_behaves_like 'secondary that is lagging primary'
      end
    end
  end
end
