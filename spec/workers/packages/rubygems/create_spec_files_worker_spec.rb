# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Rubygems::CreateSpecFilesWorker, feature_category: :package_registry do
  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  describe 'deduplication strategy' do
    it 'uses the `until_executed` strategy' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end

    it 'reschedules once if deduplicated' do
      expect(described_class.get_deduplication_options).to include(if_deduplicated: :reschedule_once)
    end
  end

  describe '#perform', :aggregate_failures do
    let_it_be(:project) { create(:project) }
    let_it_be(:package) { create(:rubygems_package, :with_metadatum, project: project) }

    subject(:perform_worker) { described_class.new.perform(project.id) }

    shared_examples 'does not trigger create spec files service' do
      it 'does not invoke CreateSpecFilesService' do
        expect(::Packages::Rubygems::CreateSpecFilesService).not_to receive(:new)

        perform_worker
      end
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id] }

      it 'creates rubygems spec file records' do
        expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

        expect { perform_worker }.to change { ::Packages::Rubygems::SpecFile.count }.by(3)
      end
    end

    context 'when the service raises an error' do
      it 'propagates the error so Sidekiq can retry' do
        expect_next_instance_of(::Packages::Rubygems::CreateSpecFilesService) do |svc|
          expect(svc).to receive(:execute).and_raise(StandardError)
        end

        expect { perform_worker }.to raise_error(StandardError)
      end
    end

    context 'when service returns an error response' do
      it 'raises a CreationFailedError so Sidekiq can retry' do
        expect_next_instance_of(::Packages::Rubygems::CreateSpecFilesService) do |svc|
          expect(svc).to receive(:execute).and_return(ServiceResponse.error(message: 'error'))
        end

        expect { perform_worker }.to raise_error(described_class::CreationFailedError, 'error')
      end
    end

    context 'when the project does not exist' do
      subject(:perform_worker) { described_class.new.perform(non_existing_record_id) }

      it_behaves_like 'does not trigger create spec files service'
    end
  end
end
