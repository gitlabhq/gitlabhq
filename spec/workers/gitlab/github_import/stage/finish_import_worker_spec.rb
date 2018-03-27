require 'spec_helper'

describe Gitlab::GithubImport::Stage::FinishImportWorker do
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

      expect(worker.logger).to receive(:info).with(an_instance_of(String))

      worker.report_import_time(project)
    end
  end
end
