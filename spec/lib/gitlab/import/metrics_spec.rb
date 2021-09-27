# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Metrics, :aggregate_failures do
  let(:importer) { :test_importer }
  let(:project) { double(:project, created_at: Time.current) }
  let(:histogram) { double(:histogram) }
  let(:counter) { double(:counter) }

  subject { described_class.new(importer, project) }

  before do
    allow(Gitlab::Metrics).to receive(:counter) { counter }
    allow(counter).to receive(:increment)
  end

  describe '#track_finished_import' do
    before do
      allow(Gitlab::Metrics).to receive(:histogram) { histogram }
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

  describe '#issues_counter' do
    it 'creates a counter for issues' do
      expect(Gitlab::Metrics).to receive(:counter).with(
        :test_importer_imported_issues_total,
        'The number of imported issues'
      )

      subject.issues_counter
    end
  end

  describe '#merge_requests_counter' do
    it 'creates a counter for issues' do
      expect(Gitlab::Metrics).to receive(:counter).with(
        :test_importer_imported_merge_requests_total,
        'The number of imported merge (pull) requests'
      )

      subject.merge_requests_counter
    end
  end
end
