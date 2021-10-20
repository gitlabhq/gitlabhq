# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::SequentialImporter do
  describe '#execute' do
    let_it_be(:project) do
      create(:project, import_url: 'http://t0ken@github.another-domain.com/repo-org/repo.git', import_type: 'github')
    end

    subject(:importer) { described_class.new(project, token: 'foo') }

    it 'imports a project in sequence' do
      expect_next_instance_of(Gitlab::Import::Metrics) do |instance|
        expect(instance).to receive(:track_start_import)
        expect(instance).to receive(:track_finished_import)
      end

      expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |instance|
        expect(instance).to receive(:execute)
      end

      described_class::SEQUENTIAL_IMPORTERS.each do |klass|
        instance = double(:instance)

        expect(klass).to receive(:new)
          .with(project, importer.client)
          .and_return(instance)

        expect(instance).to receive(:execute)
      end

      described_class::PARALLEL_IMPORTERS.each do |klass|
        instance = double(:instance)

        expect(klass).to receive(:new)
          .with(project, importer.client, parallel: false)
          .and_return(instance)

        expect(instance).to receive(:execute)
      end

      expect(importer.execute).to eq(true)
    end

    it 'raises an error' do
      exception = StandardError.new('_some_error_')

      expect_next_instance_of(Gitlab::GithubImport::Importer::RepositoryImporter) do |importer|
        expect(importer).to receive(:execute).and_raise(exception)
      end
      expect(Gitlab::Import::ImportFailureService).to receive(:track)
                                                        .with(
                                                          project_id: project.id,
                                                          exception: exception,
                                                          error_source: described_class.name,
                                                          fail_import: true,
                                                          metrics: true
                                                        ).and_call_original

      expect { importer.execute }.to raise_error(StandardError)
    end
  end
end
