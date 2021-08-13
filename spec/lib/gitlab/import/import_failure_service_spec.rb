# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::ImportFailureService do
  let_it_be(:import_type) { 'import_type' }

  let_it_be(:project) do
    create(
      :project,
      :import_started,
      import_type: import_type
    )
  end

  let(:import_state) { project.import_state }
  let(:exception) { StandardError.new('some error') }

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

      described_class.track(**arguments)

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

      described_class.track(**arguments)

      expect(project.import_state.reload.status).to eq('started')

      expect(project.import_failures).not_to be_empty
      expect(project.import_failures.last.exception_class).to eq('StandardError')
      expect(project.import_failures.last.exception_message).to eq('some error')
    end
  end

  context 'when using the project as reference' do
    context 'when it fails the import' do
      let(:arguments) do
        {
          project_id: project.id,
          exception: exception,
          error_source: 'SomeImporter',
          fail_import: true
        }
      end

      it_behaves_like 'logs the exception and fails the import'
    end

    context 'when it does not fail the import' do
      let(:arguments) do
        {
          project_id: project.id,
          exception: exception,
          error_source: 'SomeImporter',
          fail_import: false
        }
      end

      it_behaves_like 'logs the exception and does not fail the import'
    end
  end

  context 'when using the import_state as reference' do
    context 'when it fails the import' do
      let(:arguments) do
        {
          import_state: import_state,
          exception: exception,
          error_source: 'SomeImporter',
          fail_import: true
        }
      end

      it_behaves_like 'logs the exception and fails the import'
    end

    context 'when it does not fail the import' do
      let(:arguments) do
        {
          import_state: import_state,
          exception: exception,
          error_source: 'SomeImporter',
          fail_import: false
        }
      end

      it_behaves_like 'logs the exception and does not fail the import'
    end
  end
end
