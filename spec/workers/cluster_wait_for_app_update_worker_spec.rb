# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterWaitForAppUpdateWorker do
  let(:check_upgrade_progress_service) { spy }

  before do
    allow(::Clusters::Applications::CheckUpgradeProgressService).to receive(:new).and_return(check_upgrade_progress_service)
  end

  it 'runs CheckUpgradeProgressService when application is found' do
    application = create(:clusters_applications_prometheus)

    expect(check_upgrade_progress_service).to receive(:execute)

    subject.perform(application.name, application.id)
  end

  it 'does not run CheckUpgradeProgressService when application is not found' do
    expect(check_upgrade_progress_service).not_to receive(:execute)

    expect do
      subject.perform("prometheus", -1)
    end.to raise_error(ActiveRecord::RecordNotFound)
  end
end
