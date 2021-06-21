# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::FinishImportWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'marks the import as finished' do
      expect(project).to receive(:after_import)
      expect(worker).to receive(:report_import_time).with(project)

      worker.import(double(:client), project)
    end
  end

  describe '#report_import_time' do
    it 'reports the total import time' do
      expect(worker.histogram)
        .to receive(:observe)
        .with({ project: project.path_with_namespace }, a_kind_of(Numeric))
        .and_call_original

      expect(worker.counter)
        .to receive(:increment)
        .and_call_original

      expect_next_instance_of(Gitlab::Import::Logger) do |logger|
        expect(logger)
          .to receive(:info)
          .with(
            message: 'GitHub project import finished',
            import_stage: 'Gitlab::GithubImport::Stage::FinishImportWorker',
            import_source: :github,
            object_counts: {
              'fetched' => {},
              'imported' => {}
            },
            project_id: project.id,
            duration_s: a_kind_of(Numeric)
          )
      end

      worker.report_import_time(project)
    end
  end
end
