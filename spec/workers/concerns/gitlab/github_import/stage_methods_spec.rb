# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::StageMethods do
  let(:project) { create(:project) }
  let(:worker) do
    Class.new do
      def self.name
        'DummyStage'
      end

      include(Gitlab::GithubImport::StageMethods)
    end.new
  end

  describe '#perform' do
    let(:project) { create(:project, import_url: 'https://t0ken@github.com/repo/repo.git') }

    it 'returns if no project could be found' do
      expect(worker).not_to receive(:try_import)

      worker.perform(-1)
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

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'starting stage',
            import_source: :github,
            project_id: project.id,
            import_stage: 'DummyStage'
          )
        expect(logger)
          .to receive(:info)
          .with(
            message: 'stage finished',
            import_source: :github,
            project_id: project.id,
            import_stage: 'DummyStage'
          )
      end

      worker.perform(project.id)
    end

    it 'logs error when import fails' do
      exception = StandardError.new('some error')

      allow(worker)
        .to receive(:find_project)
        .with(project.id)
        .and_return(project)

      expect(worker)
        .to receive(:try_import)
        .and_raise(exception)

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'starting stage',
            import_source: :github,
            project_id: project.id,
            import_stage: 'DummyStage'
          )
        expect(logger)
          .to receive(:error)
          .with(
            message: 'stage failed',
            import_source: :github,
            project_id: project.id,
            import_stage: 'DummyStage',
            'error.message': 'some error'
          )
      end

      expect(Gitlab::ErrorTracking)
        .to receive(:track_and_raise_exception)
        .with(
          exception,
          import_source: :github,
          project_id: project.id,
          import_stage: 'DummyStage'
        )
        .and_call_original

      expect { worker.perform(project.id) }.to raise_error(exception)
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
    let(:import_state) { create(:import_state, project: project) }

    it 'returns a Project for an existing ID' do
      import_state.update_column(:status, 'started')

      expect(worker.find_project(project.id)).to eq(project)
    end

    it 'returns nil for a project that failed importing' do
      import_state.update_column(:status, 'failed')

      expect(worker.find_project(project.id)).to be_nil
    end

    it 'returns nil for a non-existing project ID' do
      expect(worker.find_project(-1)).to be_nil
    end
  end
end
