# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeactivateExpiredDeploymentsCronWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  let(:expired_pages_deployment) { create(:pages_deployment, expires_at: 3.minutes.ago) }
  let(:not_yet_expired_pages_deployment) { create(:pages_deployment, expires_at: 1.hour.from_now) }
  let(:never_expire_pages_deployment) { create(:pages_deployment, expires_at: nil) }

  it 'deactivates all expired pages deployments' do
    expect { worker.perform }
      .to change { expired_pages_deployment.reload.active? }.from(true).to(false)
      .and not_change { not_yet_expired_pages_deployment.reload.active? }
      .and not_change { never_expire_pages_deployment.reload.active? }
  end
end
