# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::ImportFailureService, :aggregate_failures do
  let_it_be(:import_type) { 'import_type' }
  let_it_be(:project) { create(:project, :import_started, import_type: import_type) }

  let(:exception) { StandardError.new('some error') }
  let(:arguments) { { project_id: project.id } }
  let(:base_arguments) { { error_source: 'SomeImporter', exception: exception }.merge(arguments) }
  let(:exe_arguments) { { fail_import: false, metrics: false } }

  describe '.track' do
    context 'with all arguments provided' do
      let(:instance) { double(:failure_service) }
      let(:instance_arguments) do
        {
          exception: exception,
          import_state: '_import_state_',
          project_id: '_project_id_',
          error_source: '_error_source_'
        }
      end

      let(:exe_arguments) do
        {
          fail_import: '_fail_import_',
          metrics: '_metrics_'
        }
      end

      it 'invokes a new instance and executes' do
        expect(described_class).to receive(:new).with(**instance_arguments).and_return(instance)
        expect(instance).to receive(:execute).with(**exe_arguments)

        described_class.track(**instance_arguments.merge(exe_arguments))
      end
    end

    context 'with only necessary arguments utilizing defaults' do
      let(:instance) { double(:failure_service) }
      let(:instance_arguments) do
        {
          exception: exception,
          import_state: nil,
          project_id: nil,
          error_source: nil
        }
      end

      let(:exe_arguments) do
        {
          fail_import: false,
          metrics: false
        }
      end

      it 'invokes a new instance and executes' do
        expect(described_class).to receive(:new).with(**instance_arguments).and_return(instance)
        expect(instance).to receive(:execute).with(**exe_arguments)

        described_class.track(exception: exception)
      end
    end
  end

  describe '#execute' do
    subject(:service) { described_class.new(**base_arguments) }

    shared_examples 'logs the exception and fails the import' do
      it 'when the failure does not abort the import' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            exception,
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        expect(Gitlab::Import::Logger)
          .to receive(:error)
          .with(
            message: 'importer failed',
            'error.message': 'some error',
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        service.execute(**exe_arguments)

        expect(project.import_state.reload.status).to eq('failed')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
      end
    end

    shared_examples 'logs the exception and does not fail the import' do
      it 'when the failure does not abort the import' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            exception,
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        expect(Gitlab::Import::Logger)
          .to receive(:error)
          .with(
            message: 'importer failed',
            'error.message': 'some error',
            project_id: project.id,
            import_type: import_type,
            source: 'SomeImporter'
          )

        service.execute(**exe_arguments)

        expect(project.import_state.reload.status).to eq('started')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
      end
    end

    context 'when tracking metrics' do
      let(:exe_arguments) { { fail_import: false, metrics: true } }

      it 'tracks the failed import' do
        metrics = double(:metrics)

        expect(Gitlab::Import::Metrics).to receive(:new).with("#{project.import_type}_importer", project).and_return(metrics)
        expect(metrics).to receive(:track_failed_import)

        service.execute(**exe_arguments)
      end
    end

    context 'when using the project as reference' do
      context 'when it fails the import' do
        let(:exe_arguments) { { fail_import: true, metrics: false } }

        it_behaves_like 'logs the exception and fails the import'
      end

      context 'when it does not fail the import' do
        it_behaves_like 'logs the exception and does not fail the import'
      end
    end

    context 'when using the import_state as reference' do
      let(:arguments) { { import_state: project.import_state } }

      context 'when it fails the import' do
        let(:exe_arguments) { { fail_import: true, metrics: false } }

        it_behaves_like 'logs the exception and fails the import'
      end

      context 'when it does not fail the import' do
        it_behaves_like 'logs the exception and does not fail the import'
      end
    end
  end
end
