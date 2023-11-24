# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeactivatedDeploymentsDeleteCronWorker, feature_category: :pages do
  subject(:worker) { described_class.new }

  let!(:pages_deployment) { create(:pages_deployment) }
  let!(:deactivated_pages_deployment) { create(:pages_deployment, deleted_at: 3.minutes.ago) }
  let!(:alt_deactivated_pages_deployment) { create(:pages_deployment, path_prefix: 'other', deleted_at: 3.minutes.ago) }

  it 'deletes all deactivated pages deployments and their files from the filesystem' do
    file_paths = [deactivated_pages_deployment.file.path, alt_deactivated_pages_deployment.file.path]

    expect { worker.perform }.to change { PagesDeployment.count }.by(-2)
    .and change { (file_paths.any? { |path| File.exist?(path) }) }.from(true).to(false)
  end
end
