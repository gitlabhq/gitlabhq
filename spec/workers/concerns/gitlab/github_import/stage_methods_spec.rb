# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::StageMethods, feature_category: :importers do
  let_it_be(:project) { create(:project, :import_started, import_url: 'https://t0ken@github.com/repo/repo.git') }
  let_it_be(:project2) { create(:project, :import_canceled) }

  let(:worker) do
    Class.new do
      def self.name
        'DummyStage'
      end

      include(Gitlab::GithubImport::StageMethods)
    end.new
  end

  describe '#perform' do
    it 'returns if no project could be found' do
      expect(worker).not_to receive(:try_import)

      worker.perform(-1)
    end

    it 'returns if the import state is canceled' do
      allow(worker)
        .to receive(:find_project)
        .with(project2.id)
        .and_return(project2)

      expect(worker).not_to receive(:try_import)

      expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            {
              message: 'starting stage',
              project_id: project2.id,
              import_stage: 'DummyStage'
            }
          )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'project import canceled',
            project_id: project2.id,
            import_stage: 'DummyStage'
          }
        )

      worker.perform(project2.id)
    end

    it 'imports the data when the project exists' do
      allow(worker)
        .to receive(:find_project)
        .with(project.id)
        .and_return(project)

      expect(worker)
        .to receive(:try_import)
        .with(
          an_instance_of(Gitlab::GithubImport::Client),
          an_instance_of(Project)
        )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'starting stage',
            project_id: project.id,
            import_stage: 'DummyStage'
          }
        )

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(
          {
            message: 'stage finished',
            project_id: project.id,
            import_stage: 'DummyStage'
          }
        )

      worker.perform(project.id)
    end

    context 'when abort_on_failure is false' do
      it 'logs error when import fails' do
        exception = StandardError.new('some error')

        allow(worker)
          .to receive(:find_project)
          .with(project.id)
          .and_return(project)

        expect(worker)
          .to receive(:try_import)
          .and_raise(exception)

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            {
              message: 'starting stage',
              project_id: project.id,
              import_stage: 'DummyStage'
            }
          )

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track)
          .with(
            {
              project_id: project.id,
              exception: exception,
              error_source: 'DummyStage',
              fail_import: false
            }
          ).and_call_original

        expect { worker.perform(project.id) }
          .to raise_error(exception)

        expect(project.import_state.reload.status).to eq('started')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
      end
    end

    context 'when abort_on_failure is true' do
      let(:worker) do
        Class.new do
          def self.name
            'DummyStage'
          end

          def abort_on_failure
            true
          end

          include(Gitlab::GithubImport::StageMethods)
        end.new
      end

      it 'logs, captures and re-raises the exception and also marks the import as failed' do
        exception = StandardError.new('some error')

        allow(worker)
          .to receive(:find_project)
          .with(project.id)
          .and_return(project)

        expect(worker)
          .to receive(:try_import)
          .and_raise(exception)

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(
            {
              message: 'starting stage',
              project_id: project.id,
              import_stage: 'DummyStage'
            }
          )

        expect(Gitlab::Import::ImportFailureService)
          .to receive(:track)
          .with(
            project_id: project.id,
            exception: exception,
            error_source: 'DummyStage',
            fail_import: true
          ).and_call_original

        expect { worker.perform(project.id) }.to raise_error(exception)

        expect(project.import_state.reload.status).to eq('failed')
        expect(project.import_state.last_error).to eq('some error')

        expect(project.import_failures).not_to be_empty
        expect(project.import_failures.last.exception_class).to eq('StandardError')
        expect(project.import_failures.last.exception_message).to eq('some error')
      end
    end
  end

  describe '#try_import' do
    it 'imports the project' do
      client = double(:client)

      expect(worker)
        .to receive(:import)
        .with(client, project)

      worker.try_import(client, project)
    end

    it 'reschedules the worker if RateLimitError was raised' do
      client = double(:client, rate_limit_resets_in: 10)

      expect(worker)
        .to receive(:import)
        .with(client, project)
        .and_raise(Gitlab::GithubImport::RateLimitError)

      expect(worker.class)
        .to receive(:perform_in)
        .with(10, project.id)

      worker.try_import(client, project)
    end
  end

  describe '#find_project' do
    it 'returns a Project for an existing ID' do
      project.import_state.update_column(:status, 'started')

      expect(worker.find_project(project.id)).to eq(project)
    end

    it 'returns nil for a project that failed importing' do
      project.import_state.update_column(:status, 'failed')

      expect(worker.find_project(project.id)).to be_nil
    end

    it 'returns nil for a non-existing project ID' do
      expect(worker.find_project(-1)).to be_nil
    end
  end
end
