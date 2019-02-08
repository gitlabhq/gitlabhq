require 'spec_helper'

describe Clusters::Applications::ScheduleInstallationService do
  def count_scheduled
    application&.class&.with_status(:scheduled)&.count || 0
  end

  shared_examples 'a failing service' do
    it 'raise an exception' do
      expect(ClusterInstallAppWorker).not_to receive(:perform_async)
      count_before = count_scheduled

      expect { service.execute }.to raise_error(StandardError)
      expect(count_scheduled).to eq(count_before)
    end
  end

  describe '#execute' do
    let(:service) { described_class.new(application) }

    context 'when application is installable' do
      let(:application) { create(:clusters_applications_helm, :installable) }

      it 'make the application scheduled' do
        expect(ClusterInstallAppWorker).to receive(:perform_async).with(application.name, kind_of(Numeric)).once

        expect { service.execute }.to change { application.class.with_status(:scheduled).count }.by(1)
      end
    end

    context 'when installation is already in progress' do
      let(:application) { create(:clusters_applications_helm, :installing) }

      it_behaves_like 'a failing service'
    end

    context 'when application is nil' do
      let(:application) { nil }

      it_behaves_like 'a failing service'
    end

    context 'when application cannot be persisted' do
      let(:application) { create(:clusters_applications_helm) }

      before do
        expect(application).to receive(:make_scheduled!).once.and_raise(ActiveRecord::RecordInvalid)
      end

      it_behaves_like 'a failing service'
    end

    context 'when application is installed' do
      let(:application) { create(:clusters_applications_helm, :installed) }

      it 'schedules an upgrade via worker' do
        expect(ClusterUpgradeAppWorker).to receive(:perform_async).with(application.name, application.id).once

        service.execute

        expect(application).to be_scheduled
      end
    end

    context 'when application is updated' do
      let(:application) { create(:clusters_applications_helm, :updated) }

      it 'schedules an upgrade via worker' do
        expect(ClusterUpgradeAppWorker).to receive(:perform_async).with(application.name, application.id).once

        service.execute

        expect(application).to be_scheduled
      end
    end
  end
end
