# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeactivatedDeploymentsDeleteCronWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  it 'deletes all deactivated pages deployments' do
    create(:pages_deployment) # active
    create(:pages_deployment, deleted_at: 3.minutes.ago) # deactivated
    create(:pages_deployment, path_prefix: 'other', deleted_at: 3.minutes.ago) # deactivated

    expect { worker.perform }.to change { PagesDeployment.count }.by(-2)
  end
end
