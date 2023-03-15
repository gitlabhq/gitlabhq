# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::FinishImportWorker, feature_category: :importers do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'marks the import as finished and reports import statistics' do
      expect(project).to receive(:after_import)
      expect_next_instance_of(Gitlab::Import::Metrics) do |instance|
        expect(instance).to receive(:track_finished_import)
        expect(instance).to receive(:duration).and_return(3.005)
      end

      expect(Gitlab::GithubImport::Logger)
        .to receive(:info)
              .with(
                {
                  message: 'GitHub project import finished',
                  import_stage: 'Gitlab::GithubImport::Stage::FinishImportWorker',
                  object_counts: {
                    'fetched' => {},
                    'imported' => {}
                  },
                  project_id: project.id,
                  duration_s: 3.01
                }
              )

      worker.import(double(:client), project)
    end
  end
end
