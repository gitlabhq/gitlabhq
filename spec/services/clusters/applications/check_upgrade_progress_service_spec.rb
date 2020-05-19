# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Applications::CheckUpgradeProgressService do
  reschedule_phashes = ::Gitlab::Kubernetes::Pod::PHASES -
    [::Gitlab::Kubernetes::Pod::SUCCEEDED, ::Gitlab::Kubernetes::Pod::FAILED, ::Gitlab].freeze

  let(:application) { create(:clusters_applications_prometheus, :updating) }
  let(:service) { described_class.new(application) }
  let(:phase) { ::Gitlab::Kubernetes::Pod::UNKNOWN }
  let(:errors) { nil }

  shared_examples 'a terminated upgrade' do
    it 'removes the POD' do
      expect(service).to receive(:remove_pod).once

      service.execute
    end
  end

  shared_examples 'a not yet terminated upgrade' do |a_phase|
    let(:phase) { a_phase }

    context "when phase is #{a_phase}" do
      context 'when not timed out' do
        it 'reschedule a new check' do
          expect(::ClusterWaitForAppUpdateWorker).to receive(:perform_in).once
          expect(service).not_to receive(:remove_pod)

          service.execute

          expect(application).to be_updating
          expect(application.status_reason).to be_nil
        end
      end

      context 'when timed out' do
        let(:application) { create(:clusters_applications_prometheus, :timed_out, :updating) }

        it_behaves_like 'a terminated upgrade'

        it 'make the application update errored' do
          expect(::ClusterWaitForAppUpdateWorker).not_to receive(:perform_in)

          service.execute

          expect(application).to be_update_errored
          expect(application.status_reason).to eq("Update timed out")
        end
      end
    end
  end

  before do
    allow(service).to receive(:phase).once.and_return(phase)

    allow(service).to receive(:errors).and_return(errors)
    allow(service).to receive(:remove_pod).and_return(nil)
  end

  describe '#execute' do
    context 'when upgrade pod succeeded' do
      let(:phase) { ::Gitlab::Kubernetes::Pod::SUCCEEDED }

      it_behaves_like 'a terminated upgrade'

      it 'make the application upgraded' do
        expect(::ClusterWaitForAppUpdateWorker).not_to receive(:perform_in)

        service.execute

        expect(application).to be_updated
        expect(application.status_reason).to be_nil
      end
    end

    context 'when upgrade pod failed' do
      let(:phase) { ::Gitlab::Kubernetes::Pod::FAILED }
      let(:errors) { 'test installation failed' }

      it_behaves_like 'a terminated upgrade'

      it 'make the application update errored' do
        service.execute

        expect(application).to be_update_errored
        expect(application.status_reason).to eq(errors)
      end
    end

    reschedule_phashes.each { |phase| it_behaves_like 'a not yet terminated upgrade', phase }
  end
end
