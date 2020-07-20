# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Metrics do
  let(:importer) { :test_importer }
  let(:project) { create(:project) }
  let(:histogram) { double(:histogram) }
  let(:counter) { double(:counter) }

  subject { described_class.new(importer, project) }

  describe '#report_import_time' do
    before do
      allow(Gitlab::Metrics).to receive(:counter) { counter }
      allow(Gitlab::Metrics).to receive(:histogram) { histogram }
      allow(counter).to receive(:increment)
      allow(counter).to receive(:observe)
    end

    it 'emits importer metrics' do
      expect(Gitlab::Metrics).to receive(:counter).with(
        :test_importer_imported_projects_total,
        'The number of imported projects'
      )

      expect(Gitlab::Metrics).to receive(:histogram).with(
        :test_importer_total_duration_seconds,
        'Total time spent importing projects, in seconds',
        {},
        described_class::IMPORT_DURATION_BUCKETS
      )

      expect(counter).to receive(:increment)
      expect(histogram).to receive(:observe).with({ importer: :test_importer }, anything)

      subject.track_finished_import
    end
  end
end
