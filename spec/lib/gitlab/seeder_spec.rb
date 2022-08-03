# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Seeder do
  describe Namespace do
    subject { described_class }

    it 'has not_mass_generated scope' do
      expect { Namespace.not_mass_generated }.to raise_error(NoMethodError)

      Gitlab::Seeder.quiet do
        expect { Namespace.not_mass_generated }.not_to raise_error
      end
    end

    it 'includes NamespaceSeed module' do
      Gitlab::Seeder.quiet do
        is_expected.to include_module(Gitlab::Seeder::NamespaceSeed)
      end
    end
  end

  describe '.quiet' do
    let(:database_base_models) do
      {
        main: ActiveRecord::Base,
        ci: Ci::ApplicationRecord
      }
    end

    it 'disables database logging' do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return(database_base_models.with_indifferent_access)

      described_class.quiet do
        expect(ApplicationRecord.logger).to be_nil
        expect(Ci::ApplicationRecord.logger).to be_nil
      end

      expect(ApplicationRecord.logger).not_to be_nil
      expect(Ci::ApplicationRecord.logger).not_to be_nil
    end

    it 'disables mail deliveries' do
      expect(ActionMailer::Base.perform_deliveries).to eq(true)

      described_class.quiet do
        expect(ActionMailer::Base.perform_deliveries).to eq(false)
      end

      expect(ActionMailer::Base.perform_deliveries).to eq(true)
    end

    it 'disables new note notifications' do
      note = create(:note_on_issue)

      notification_service = NotificationService.new

      expect(notification_service).to receive(:send_new_note_notifications).twice

      notification_service.new_note(note)

      described_class.quiet do
        expect(notification_service.new_note(note)).to eq(nil)
      end

      notification_service.new_note(note)
    end
  end

  describe '.log_message' do
    it 'prepends timestamp to the logged message' do
      freeze_time do
        message = "some message."
        expect { described_class.log_message(message) }.to output(/#{Time.current}: #{message}/).to_stdout
      end
    end
  end

  describe ::Gitlab::Seeder::Ci::DailyBuildGroupReportResult do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }

    subject(:build_report) do
      described_class.new(project)
    end

    describe '#seed' do
      it 'creates daily build results for the project' do
        expect { build_report.seed }.to change {
          Ci::DailyBuildGroupReportResult.count
        }.by(Gitlab::Seeder::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
      end

      it 'matches project data with last report' do
        build_report.seed

        report = project.daily_build_group_report_results.last
        reports_count = project.daily_build_group_report_results.count

        expect(build.group_name).to eq(report.group_name)
        expect(pipeline.source_ref_path).to eq(report.ref_path)
        expect(pipeline.default_branch?).to eq(report.default_branch)
        expect(reports_count).to eq(Gitlab::Seeder::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
      end

      it 'does not raise error on RecordNotUnique' do
        build_report.seed
        build_report.seed

        reports_count = project.daily_build_group_report_results.count

        expect(reports_count).to eq(Gitlab::Seeder::Ci::DailyBuildGroupReportResult::COUNT_OF_DAYS)
      end
    end
  end
end
