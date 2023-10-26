# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ReleasesSubscriptionWorker, feature_category: :release_orchestration do
  describe '#perform' do
    let(:worker) { described_class.new }
    let(:project) { build_stubbed :project, :public }
    let(:subscription) { build_stubbed :activity_pub_releases_subscription, project: project }
    let(:inbox_resolver_service) { instance_double('ActivityPub::InboxResolverService', execute: true) }
    let(:accept_follow_service) { instance_double('ActivityPub::AcceptFollowService', execute: true) }

    before do
      allow(ActivityPub::ReleasesSubscription).to receive(:find_by_id) { subscription }
      allow(subscription).to receive(:destroy).and_return(true)
      allow(ActivityPub::InboxResolverService).to receive(:new) { inbox_resolver_service }
      allow(ActivityPub::AcceptFollowService).to receive(:new) { accept_follow_service }
    end

    context 'when the project is public' do
      before do
        worker.perform(subscription.id)
      end

      context 'when inbox url has not been resolved yet' do
        it 'calls the service to resolve the inbox url' do
          expect(inbox_resolver_service).to have_received(:execute)
        end

        it 'calls the service to send out the Accept activity' do
          expect(accept_follow_service).to have_received(:execute)
        end
      end

      context 'when inbox url has been resolved' do
        context 'when shared inbox url has not been resolved' do
          let(:subscription) { build_stubbed :activity_pub_releases_subscription, :inbox, project: project }

          it 'calls the service to resolve the inbox url' do
            expect(inbox_resolver_service).to have_received(:execute)
          end

          it 'calls the service to send out the Accept activity' do
            expect(accept_follow_service).to have_received(:execute)
          end
        end

        context 'when shared inbox url has been resolved' do
          let(:subscription) do
            build_stubbed :activity_pub_releases_subscription, :inbox, :shared_inbox, project: project
          end

          it 'does not call the service to resolve the inbox url' do
            expect(inbox_resolver_service).not_to have_received(:execute)
          end

          it 'calls the service to send out the Accept activity' do
            expect(accept_follow_service).to have_received(:execute)
          end
        end
      end
    end

    shared_examples 'failed job' do
      it 'does not resolve inbox url' do
        expect(inbox_resolver_service).not_to have_received(:execute)
      end

      it 'does not send out Accept activity' do
        expect(accept_follow_service).not_to have_received(:execute)
      end
    end

    context 'when the subscription does not exist' do
      before do
        allow(ActivityPub::ReleasesSubscription).to receive(:find_by_id).and_return(nil)
        worker.perform(subscription.id)
      end

      it_behaves_like 'failed job'
    end

    shared_examples 'non public project' do
      it_behaves_like 'failed job'

      it 'deletes the subscription' do
        expect(subscription).to have_received(:destroy)
      end
    end

    context 'when project has changed to internal' do
      before do
        worker.perform(subscription.id)
      end

      let(:project) { build_stubbed :project, :internal }

      it_behaves_like 'non public project'
    end

    context 'when project has changed to private' do
      before do
        worker.perform(subscription.id)
      end

      let(:project) { build_stubbed :project, :private }

      it_behaves_like 'non public project'
    end
  end

  describe '#sidekiq_retries_exhausted' do
    let(:project) { build_stubbed :project, :public }
    let(:subscription) { build_stubbed :activity_pub_releases_subscription, project: project }
    let(:job) { { 'args' => [project.id, subscription.id], 'error_message' => 'Error' } }

    before do
      allow(Project).to receive(:find) { project }
      allow(ActivityPub::ReleasesSubscription).to receive(:find_by_id) { subscription }
    end

    it 'delete the subscription' do
      expect(subscription).to receive(:destroy)

      described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
    end
  end
end
