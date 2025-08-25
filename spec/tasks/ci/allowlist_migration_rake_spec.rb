# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ci:job_tokens:allowlist rake tasks', feature_category: :secrets_management do
  let(:task_class) { ::Ci::JobToken::AllowlistMigrationTask }
  let(:user) { create(:user, :admin_bot) }

  before do
    Rake.application.rake_require('tasks/ci/allowlist_migration')
  end

  describe 'configuration' do
    context 'when ONLY_PROJECT_IDS is set' do
      it 'runs the task with only the supplied IDs' do
        stub_env('ONLY_PROJECT_IDS', '1,2,3')
        expect(task_class).to receive(:new).with(
          only_ids: '1,2,3', exclude_ids: nil, preview: nil, user: user, concurrency: 1
        ).and_call_original do |task|
          expect(task.only_ids).to eq('1,2,3')
        end

        run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
      end
    end

    context 'when EXCLUDE_PROJECT_IDS is set' do
      it 'runs the task without the excluded IDs' do
        stub_env('EXCLUDE_PROJECT_IDS', '1,2,3')
        expect(task_class).to receive(:new).with(
          only_ids: nil, exclude_ids: '1,2,3', preview: nil, user: user, concurrency: 1
        ).and_call_original do |task|
          expect(task.exclude_ids).to eq('1,2,3')
        end

        run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
      end
    end

    it 'shows a configuration error if the ONLY_PROJECT_IDS and EXCLUDE_PROJECT_IDS are both set' do
      stub_env('ONLY_PROJECT_IDS', '1,2,3')
      stub_env('EXCLUDE_PROJECT_IDS', '2,3,4')

      expect(task_class).to receive(:new).with(only_ids: '1,2,3', exclude_ids: '2,3,4',
        preview: nil, user: user, concurrency: 1).and_call_original do |task|
        expect(task).to receive(:configuration_error)
        expect(task).not_to receive(:migrate!)
      end

      run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
    end

    it 'runs the task in preview mode if the preview flag is set' do
      stub_env('PREVIEW', "1")

      expect(task_class).to receive(:new).with(
        only_ids: nil, exclude_ids: nil, preview: "1", user: user, concurrency: 1
      ).and_call_original do |task|
        expect(task.preview?).to be(true)
      end

      run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
    end

    it 'shows the preview notice if the preview flag is set' do
      stub_env('PREVIEW', "1")

      expect(task_class).to receive(:new).with(
        only_ids: nil, exclude_ids: nil, preview: "1", user: user, concurrency: 1
      ).and_call_original do |task|
        expect(task).to receive(:valid_configuration?).and_call_original
        expect(task).to receive(:preview?)
        expect(task).not_to receive(:preview_notice)
        expect(task).to receive(:migrate!)
      end

      run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
    end

    it 'does not shows the preview notice if the preview flag is not set' do
      expect(task_class).to receive(:new).with(
        only_ids: nil, exclude_ids: nil, preview: nil, user: user, concurrency: 1
      ).and_call_original do |task|
        expect(task).to receive(:valid_configuration?).and_call_original
        expect(task).to receive(:preview?)
        expect(task).not_to receive(:preview_notice)
        expect(task).to receive(:migrate!)
      end

      run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
    end

    it 'runs the task with a configured concurrency if specified' do
      stub_env('CONCURRENCY', "4")

      expect(task_class).to receive(:new).with(
        only_ids: nil, exclude_ids: nil, preview: nil, user: user, concurrency: 4
      ).and_call_original do |task|
        expect(task.preview?).to be(true)
      end

      run_rake_task('ci:job_tokens:allowlist:autopopulate_and_enforce')
    end
  end
end
