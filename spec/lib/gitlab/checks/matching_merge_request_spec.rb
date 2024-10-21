# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::MatchingMergeRequest, feature_category: :source_code_management do
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

    context 'with load balancing enabled', :redis do
      let(:session) { ::Gitlab::Database::LoadBalancing::SessionMap.current(project.load_balancer) }

      before do
        # Need to mock as though we actually have replicas
        allow(::ApplicationRecord.load_balancer)
          .to receive(:primary_only?)
          .and_return(false)

        # Put some sticking position for the primary in Redis
        ::ApplicationRecord.sticking.stick(:project, project.id)

        Gitlab::Database::LoadBalancing::SessionMap.clear_session

        # Mock the load balancer result since we don't actually have real replicas to match against
        expect(::ApplicationRecord.load_balancer)
          .to receive(:select_up_to_date_host)
          .and_return(load_balancer_result)

        # Expect sticking called with correct arguments but don't mock it so that we can also test the internal
        # behaviour of updating the Session.use_primary?
        expect(::ApplicationRecord.sticking)
          .to receive(:find_caught_up_replica)
          .with(:project, project.id, use_primary_on_empty_location: true)
          .and_call_original
      end

      after do
        Gitlab::Database::LoadBalancing::SessionMap.clear_session
      end

      context 'when any secondary is caught up' do
        let(:load_balancer_result) { ::Gitlab::Database::LoadBalancing::LoadBalancer::ANY_CAUGHT_UP }

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

      context 'when all secondaries are lagging behind' do
        let(:load_balancer_result) { ::Gitlab::Database::LoadBalancing::LoadBalancer::NONE_CAUGHT_UP }

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
    end
  end
end
