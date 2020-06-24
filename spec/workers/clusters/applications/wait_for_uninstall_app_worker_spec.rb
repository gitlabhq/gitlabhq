# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Applications::WaitForUninstallAppWorker, '#perform' do
  let(:app) { create(:clusters_applications_helm) }
  let(:app_name) { app.name }
  let(:app_id) { app.id }

  subject { described_class.new.perform(app_name, app_id) }

  context 'app exists' do
    let(:service) { instance_double(Clusters::Applications::CheckUninstallProgressService) }

    it 'calls the check service' do
      expect(Clusters::Applications::CheckUninstallProgressService).to receive(:new).with(app).and_return(service)
      expect(service).to receive(:execute).once

      subject
    end
  end

  context 'app does not exist' do
    let(:app_id) { 0 }

    it 'does not call the check service' do
      expect(Clusters::Applications::CheckUninstallProgressService).not_to receive(:new)

      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
