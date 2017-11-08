require 'spec_helper'

describe Gitlab::GithubImport::StageMethods do
  let(:project) { create(:project) }
  let(:worker) do
    Class.new { include(Gitlab::GithubImport::StageMethods) }.new
  end

  describe '#perform' do
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

      worker.perform(project.id)
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
      project.update_column(:import_status, 'started')

      expect(worker.find_project(project.id)).to eq(project)
    end

    it 'returns nil for a project that failed importing' do
      project.update_column(:import_status, 'failed')

      expect(worker.find_project(project.id)).to be_nil
    end

    it 'returns nil for a non-existing project ID' do
      expect(worker.find_project(-1)).to be_nil
    end
  end
end
