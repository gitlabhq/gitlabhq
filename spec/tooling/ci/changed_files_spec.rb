# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/ci/changed_files'

RSpec.describe CI::ChangedFiles, feature_category: :tooling do
  let(:instance) { described_class.new }

  describe '#get_changed_files_in_merged_results_pipeline' do
    let(:git_diff_output) { "file1.js\nfile2.rb\nfile3.vue\nfile4.graphql" }

    before do
      allow(instance).to receive(:`)
      .with('git diff --name-only --diff-filter=d HEAD~..HEAD')
      .and_return(git_diff_output)
    end

    context 'when git diff is run in a merged results pipeline' do
      it 'returns an array when there are changed files' do
        expect(instance.get_changed_files_in_merged_results_pipeline)
        .to match_array(['file1.js', 'file2.rb', 'file3.vue', 'file4.graphql'])
      end

      context "when there are no changed files" do
        let(:git_diff_output) { "" }

        it 'returns an empty array' do
          expect(instance.get_changed_files_in_merged_results_pipeline).to eq([])
        end
      end
    end
  end

  describe '#filter_and_get_changed_files_in_mr' do
    let(:changed_files_output) { ['file1.js', 'file2.rb', 'file3.vue'] }

    before do
      allow(instance).to receive(
        :get_changed_files_in_merged_results_pipeline).and_return(changed_files_output)
    end

    context 'when there are changed files' do
      context 'when filter value matches' do
        it 'returns filtered files' do
          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/))
          .to match_array(['file1.js', 'file3.vue'])
        end

        it 'returns all files when filter is empty' do
          expect(instance.filter_and_get_changed_files_in_mr)
          .to match_array(changed_files_output)
        end
      end

      context 'when filter does not match' do
        let(:changed_files_output) { ['file1.txt', 'file2.rb'] }

        it 'returns empty array when no files match filter' do
          expect(instance.filter_and_get_changed_files_in_mr(filter_pattern: /\.(js|vue)$/)).to eq([])
        end
      end
    end

    context 'when there are no changed files' do
      let(:changed_files_output) { [] }

      it 'returns an empty array' do
        expect(instance.filter_and_get_changed_files_in_mr).to eq([])
      end
    end
  end

  describe '#run_eslint_for_changed_files' do
    let(:eslint_command) do
      ['yarn', 'run', 'lint:eslint', '--no-warn-ignored', '--no-error-on-unmatched-pattern', '--format', 'gitlab',
        'file1.js', 'file2.vue']
    end

    let(:console_message) { /Running ESLint for changed files.../i }

    context 'when there are changed files to lint' do
      let(:files) { ['file1.js', 'file2.vue'] }

      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
      end

      it 'runs eslint with the correct arguments and returns exit 0 on success' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(true)
        expect(instance).to receive(:puts).with(console_message)

        status = instance_double(Process::Status, exitstatus: 0)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(0)
      end

      it 'runs eslint with the correct arguments and returns exit 1 on failure' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(false)

        status = instance_double(Process::Status, exitstatus: 1)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(1)
      end
    end

    context 'when there are no changed files to lint' do
      let(:no_files_msg) { /No files were changed. Skipping/i }

      it 'does not run eslint and returns exit code 0' do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return([])

        expect(instance).to receive(:puts).with(console_message).ordered
        expect(instance).to receive(:puts).with(no_files_msg).ordered

        expect(instance).not_to receive(:system)
        expect(instance.run_eslint_for_changed_files).to eq(0)
      end
    end

    context 'when a single todo file has been changed' do
      let(:eslint_command) do
        ['yarn', 'run', 'lint:eslint', '--no-warn-ignored', '--no-error-on-unmatched-pattern', '--format', 'gitlab',
          '.eslint_todo/vue-no-unused-properties.mjs',
          'app/assets/javascripts/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue',
          'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_comment_form.vue',
          'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_edit_note.vue',
          'app/assets/javascripts/admin/statistics_panel/components/app.vue',
          'app/assets/javascripts/badges/components/badge.vue',
          'app/assets/javascripts/badges/components/badge_form.vue',
          'app/assets/javascripts/batch_comments/components/draft_note.vue']
      end

      let(:files) { ['.eslint_todo/vue-no-unused-properties.mjs'] }
      let(:git_diff_output) do
        <<-DIFF
          diff --git a/.eslint_todo/vue-no-unused-properties.mjs b/.eslint_todo/vue-no-unused-properties.mjs
          index 81f0b2cbcf84..ef936567f2e8 100644
          --- a/.eslint_todo/vue-no-unused-properties.mjs
          +++ b/.eslint_todo/vue-no-unused-properties.mjs
          @@ -3,13 +3,7 @@
            */
          export default {
            files: [
          -    'app/assets/javascripts/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue',
          -    'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_comment_form.vue',
          -    'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_edit_note.vue',
          -    'app/assets/javascripts/admin/statistics_panel/components/app.vue',
          -    'app/assets/javascripts/badges/components/badge.vue',
          -    'app/assets/javascripts/badges/components/badge_form.vue',
          -    'app/assets/javascripts/batch_comments/components/draft_note.vue',
          +    'app/assets/javascripts/batch_comments/components/preview_item.vue',
              'app/assets/javascripts/behaviors/components/json_table.vue',
              'app/assets/javascripts/behaviors/components/sandboxed_mermaid.vue',
        DIFF
      end

      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
        allow(instance).to receive(:`)
          .with('git diff HEAD~..HEAD -- .eslint_todo/vue-no-unused-properties.mjs')
          .and_return(git_diff_output)
      end

      it 'runs eslint with the correct arguments and returns exit 1 on failure' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(false)

        status = instance_double(Process::Status, exitstatus: 1)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(1)
      end
    end

    context 'when several todo files have been changed' do
      let(:eslint_command) do
        ['yarn', 'run', 'lint:eslint', '--no-warn-ignored', '--no-error-on-unmatched-pattern', '--format', 'gitlab',
          '.eslint_todo/vue-no-unused-properties.mjs',
          'app/assets/javascripts/projects/project_new.js',
          'app/assets/javascripts/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue',
          'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_comment_form.vue']
      end

      let(:files) { ['.eslint_todo/vue-no-unused-properties.mjs'] }
      let(:git_diff_output) do
        <<-DIFF
          diff --git a/.eslint_todo/index.mjs b/.eslint_todo/index.mjs
          index 88c73e337a50..1c27203d62cb 100644
          --- a/.eslint_todo/index.mjs
          +++ b/.eslint_todo/index.mjs
          @@ -1 +1,3 @@
          export { default as vueNoUnusedProperties } from './vue-no-unused-properties.mjs';
          +
          +export { default as noUnusedVars } from './no-unused-vars.mjs';
          diff --git a/.eslint_todo/no-unused-vars.mjs b/.eslint_todo/no-unused-vars.mjs
          index dbd4c28b65c8..f11106b14857 100644
          --- a/.eslint_todo/no-unused-vars.mjs
          +++ b/.eslint_todo/no-unused-vars.mjs
          @@ -3,7 +3,6 @@
            */
          export default {
            files: [
          -    'app/assets/javascripts/projects/project_new.js',
              'app/assets/javascripts/vue_shared/components/customizable_dashboard/dashboard_editor/available_visualizations_drawer.vue',
              'app/assets/javascripts/vue_shared/components/customizable_dashboard/utils.js',
            ],
          diff --git a/.eslint_todo/vue-no-unused-properties.mjs b/.eslint_todo/vue-no-unused-properties.mjs
          index 81f0b2cbcf84..cf56bd55554b 100644
          --- a/.eslint_todo/vue-no-unused-properties.mjs
          +++ b/.eslint_todo/vue-no-unused-properties.mjs
          @@ -3,8 +3,6 @@
            */
          export default {
            files: [
          -    'app/assets/javascripts/add_context_commits_modal/components/add_context_commits_modal_wrapper.vue',
          -    'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_comment_form.vue',
              'app/assets/javascripts/admin/abuse_report/components/notes/abuse_report_edit_note.vue',
              'app/assets/javascripts/admin/statistics_panel/components/app.vue',
              'app/assets/javascripts/badges/components/badge.vue',

        DIFF
      end

      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
        allow(instance).to receive(:`)
          .with('git diff HEAD~..HEAD -- .eslint_todo/vue-no-unused-properties.mjs')
          .and_return(git_diff_output)
      end

      it 'runs eslint with the correct arguments and returns exit 1 on failure' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(false)

        status = instance_double(Process::Status, exitstatus: 1)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(1)
      end
    end

    context 'when todo files have been changed but no ignored file was removed from them' do
      let(:eslint_command) do
        ['yarn', 'run', 'lint:eslint', '--no-warn-ignored', '--no-error-on-unmatched-pattern', '--format', 'gitlab',
          '.eslint_todo/vue-no-unused-properties.mjs']
      end

      let(:files) { ['.eslint_todo/vue-no-unused-properties.mjs'] }
      let(:git_diff_output) do
        <<-DIFF
          diff --git a/.eslint_todo/no-unused-vars.mjs b/.eslint_todo/no-unused-vars.mjs
          new file mode 100644
          index 000000000000..dbd4c28b65c8
          --- /dev/null
          +++ b/.eslint_todo/no-unused-vars.mjs
          @@ -0,0 +1,13 @@
          +/**
          + * Generated by `scripts/frontend/generate_eslint_todo_list.mjs`.
          + */
          +export default {
          +  files: [
          +    'app/assets/javascripts/projects/project_new.js',
          +    'app/assets/javascripts/vue_shared/components/customizable_dashboard/dashboard_editor/available_visualizations_drawer.vue',
          +    'app/assets/javascripts/vue_shared/components/customizable_dashboard/utils.js',
          +  ],
          +  rules: {
          +    'no-unused-vars': 'off',
          +  },
          +};

        DIFF
      end

      before do
        allow(instance).to receive(:filter_and_get_changed_files_in_mr).and_return(files)
        allow(instance).to receive(:`)
          .with('git diff HEAD~..HEAD -- .eslint_todo/vue-no-unused-properties.mjs')
          .and_return(git_diff_output)
      end

      it 'runs eslint with the correct arguments and returns exit 1 on failure' do
        expect(instance).to receive(:system).with(*eslint_command).and_return(false)

        status = instance_double(Process::Status, exitstatus: 1)
        allow(instance).to receive(:last_command_status).and_return(status)

        expect(instance.run_eslint_for_changed_files).to eq(1)
      end
    end
  end

  describe 'Run CLI commands' do
    it 'returns 0 for empty args' do
      allow(ARGV).to receive(:empty?).and_return(true)

      expect(instance.process_command_and_determine_exit_status).to eq(0)
    end

    it 'returns 0 when eslint succeeds' do
      allow(ARGV).to receive(:first).and_return('eslint')
      allow(instance).to receive(:run_eslint_for_changed_files).and_return(0)

      expect(instance.process_command_and_determine_exit_status).to eq(0)
    end

    it 'returns exit code when eslint fails' do
      allow(ARGV).to receive(:first).and_return('eslint')
      allow(instance).to receive(:run_eslint_for_changed_files).and_return(11)

      expect(instance.process_command_and_determine_exit_status).to eq(11)
    end

    it 'returns 1 for unknown commands' do
      allow(ARGV).to receive(:first).and_return('unknown')

      expect(instance.process_command_and_determine_exit_status).to eq(1)
    end
  end
end
