# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::Metrics, :aggregate_failures do
  let(:importer) { :test_importer }
  let(:project) { build(:project, id: non_existing_record_id, created_at: Time.current) }
  let(:histogram) { double(:histogram) }
  let(:counter) { double(:counter) }

  subject { described_class.new(importer, project) }

  before do
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
        expect_no_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'failed'
        )

        subject.track_failed_import
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
        allow(project).to receive(:import_status).and_return('failed')
      end

      it 'emits importer metrics' do
        expect(subject).to receive(:track_usage_event).with(:github_import_project_failure, project.id)

        subject.track_failed_import

        expect_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'failed'
        )
      end
    end
  end

  describe '#track_finished_import' do
    context 'when project is a github import' do
      before do
        project.import_type = 'github'
        allow(Gitlab::Metrics).to receive(:counter) { counter }
        allow(Gitlab::Metrics).to receive(:histogram) { histogram }
        allow(project).to receive(:beautified_import_status_name).and_return('completed')
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

        expect_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'completed'
        )

        expect(subject.duration).not_to be_nil
      end

      context 'when import is partially completed' do
        before do
          allow(project).to receive(:beautified_import_status_name).and_return('partially completed')
        end

        it 'emits snowplow metrics' do
          expect(subject).to receive(:track_usage_event).with(:github_import_project_partially_completed, project.id)

          subject.track_finished_import

          expect_snowplow_event(
            category: 'Import::GithubService',
            action: 'create',
            label: 'github_import_project_state',
            project: project,
            import_type: 'github', state: 'partially completed'
          )
        end
      end
    end

    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        expect(subject).not_to receive(:track_usage_event)

        subject.track_finished_import

        expect_no_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'completed'
        )
      end
    end
  end

  describe '#track_cancelled_import' do
    context 'when project is not a github import' do
      it 'does not emit importer metrics' do
        expect(subject).not_to receive(:track_usage_event)
        expect_no_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'canceled'
        )

        subject.track_canceled_import
      end
    end

    context 'when project is a github import' do
      before do
        project.import_type = 'github'
        allow(project).to receive(:import_status).and_return('canceled')
      end

      it 'emits importer metrics' do
        expect(subject).to receive(:track_usage_event).with(:github_import_project_cancelled, project.id)

        subject.track_canceled_import

        expect_snowplow_event(
          category: 'Import::GithubService',
          action: 'create',
          label: 'github_import_project_state',
          project: project,
          import_type: 'github', state: 'canceled'
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
