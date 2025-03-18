# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeactivateExpiredDeploymentsCronWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  let!(:expired_pages_deployment) { create(:pages_deployment, expires_at: 3.minutes.ago) }
  let!(:not_yet_expired_pages_deployment) { create(:pages_deployment, expires_at: 1.hour.from_now) }
  let!(:never_expire_pages_deployment) { create(:pages_deployment, expires_at: nil) }

  it 'deactivates all expired pages deployments' do
    expect { worker.perform }
      .to change { expired_pages_deployment.reload.active? }.from(true).to(false)
      .and not_change { not_yet_expired_pages_deployment.reload.active? }
      .and not_change { never_expire_pages_deployment.reload.active? }
  end

  it 'logs extra metadata on done' do
    expect(worker).to receive(:log_extra_metadata_on_done).with(:deactivate_expired_pages_deployments, {
      deactivated_deployments: 1,
      duration: be > 0
    })

    worker.perform
  end

  it 'uses the expected values for batching and limiting' do
    expect(Pages::DeactivateExpiredDeploymentsCronWorker::MAX_NUM_DELETIONS).to be(10000)
    expect(Pages::DeactivateExpiredDeploymentsCronWorker::BATCH_SIZE).to be(1000)
  end

  describe 'batching and limiting' do
    before do
      stub_const('Pages::DeactivateExpiredDeploymentsCronWorker::MAX_NUM_DELETIONS', 9)
      stub_const('Pages::DeactivateExpiredDeploymentsCronWorker::BATCH_SIZE', 5)

      11.times do # we already have 1 deployment from the outer scope
        create(:pages_deployment, expires_at: 3.minutes.ago)
      end
    end

    it 'processes a maximum number of deletions, but will complete the last batch of deletions' do
      expect { worker.perform }
        .to change { PagesDeployment.active.expired.count }.from(12).to(2)
    end
  end
end
