# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Metrics, :aggregate_failures do
  let(:importer) { :test_importer }
  let(:project) { build(:project, id: non_existing_record_id, created_at: Time.current) }
  let(:histogram) { double(:histogram) }
  let(:counter) { double(:counter) }

  subject { described_class.new(importer, project) }

  before do
    allow(Gitlab::Metrics).to receive(:counter) { counter }
    allow(counter).to receive(:increment)
    allow(histogram).to receive(:observe)
  end

  describe '#track_start_import' do
    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        expect(subject).not_to receive(:track_usage_event)

        subject.track_start_import
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
      end

      it 'emits importer metrics' do
        expect(subject).to receive(:track_usage_event).with(:github_import_project_start, project.id)

        subject.track_start_import
      end
    end
  end

  describe '#track_failed_import' do
    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        expect(subject).not_to receive(:track_usage_event)

        subject.track_failed_import
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
      end

      it 'emits importer metrics' do
        expect(subject).to receive(:track_usage_event).with(:github_import_project_failure, project.id)

        subject.track_failed_import
      end
    end
  end

  describe '#track_import_state' do
    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        subject.track_import_state

        expect_no_snowplow_event(
          category: :test_importer,
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          extra: { import_type: 'github', state: 'failed' }
        )
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
        allow(project).to receive(:import_status).and_return('failed')
      end

      it 'emits importer metrics' do
        subject.track_import_state

        expect_snowplow_event(
          category: :test_importer,
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          extra: { import_type: 'github', state: 'failed' }
        )
      end
    end
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

      subject.track_finished_import

      expect(subject.duration).not_to be_nil
    end

    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        expect(subject).not_to receive(:track_usage_event)

        subject.track_finished_import

        expect(histogram).to have_received(:observe).with({ importer: :test_importer }, anything)
        expect_no_snowplow_event(
          category: :test_importer,
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          extra: { import_type: 'github', state: 'completed' }
        )
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
        allow(project).to receive(:import_status).and_return('finished')
        allow(project).to receive(:import_finished?).and_return(true)
      end

      it 'emits snowplow metrics' do
        subject.track_finished_import

        expect_snowplow_event(
          category: :test_importer,
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          extra: { import_type: 'github', state: 'completed' }
        )
      end
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
