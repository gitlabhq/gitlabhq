# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/analytics_instrumentation'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::AnalyticsInstrumentation, feature_category: :service_ping do
  include_context "with dangerfile"

  subject(:analytics_instrumentation) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper) }
  let(:previous_label_to_add) { 'label_to_add' }
  let(:labels_to_add) { [previous_label_to_add] }
  let(:ci_env) { true }
  let(:has_analytics_instrumentation_label) { true }

  before do
    allow(fake_helper).to receive(:changed_lines).and_return(changed_lines) if defined?(changed_lines)
    allow(fake_helper).to receive(:labels_to_add).and_return(labels_to_add)
    allow(fake_helper).to receive(:ci?).and_return(ci_env)
    allow(fake_helper).to receive(:mr_has_labels?).with('analytics instrumentation').and_return(has_analytics_instrumentation_label)
  end

  describe '#check!' do
    subject { analytics_instrumentation.check! }

    let(:markdown_formatted_list) { 'markdown formatted list' }
    let(:review_pending_label) { 'analytics instrumentation::review pending' }
    let(:approved_label) { 'analytics instrumentation::approved' }
    let(:changed_files) { ['metrics/counts_7d/test_metric.yml'] }
    let(:changed_lines) { ['+tier: ee'] }
    let(:fake_changes) { instance_double(Gitlab::Dangerfiles::Changes, files: changed_files) }

    before do
      allow(fake_changes).to receive(:by_category).with(:analytics_instrumentation).and_return(fake_changes)
      allow(fake_helper).to receive(:changes).and_return(fake_changes)
      allow(fake_helper).to receive(:all_changed_files).and_return(changed_files)
      allow(fake_helper).to receive(:markdown_list).with(changed_files).and_return(markdown_formatted_list)
    end

    shared_examples "doesn't add new labels" do
      it "doesn't add new labels" do
        subject

        expect(labels_to_add).to match_array [previous_label_to_add]
      end
    end

    shared_examples "doesn't add new warnings" do
      it "doesn't add new warnings" do
        expect(analytics_instrumentation).not_to receive(:warn)

        subject
      end
    end

    shared_examples 'adds new labels' do
      it 'adds new labels' do
        subject

        expect(labels_to_add).to match_array [previous_label_to_add, review_pending_label]
      end

      it 'receives all the changed files by calling the correct helper method', :aggregate_failures do
        expect(fake_helper).not_to receive(:changes_by_category)
        expect(fake_helper).to receive(:changes)
        expect(fake_changes).to receive(:by_category).with(:analytics_instrumentation)
        expect(fake_changes).to receive(:files)

        subject
      end
    end

    context 'with growth experiment label' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('growth experiment').and_return(true)
      end

      include_examples "doesn't add new labels"
      include_examples "doesn't add new warnings"
    end

    context 'without growth experiment label' do
      before do
        allow(fake_helper).to receive(:mr_has_labels?).with('growth experiment').and_return(false)
      end

      context 'with approved label' do
        let(:mr_labels) { [approved_label] }

        include_examples "doesn't add new labels"
        include_examples "doesn't add new warnings"
      end

      context 'without approved label' do
        include_examples 'adds new labels'

        it 'warns with proper message' do
          expect(analytics_instrumentation).to receive(:warn).with(%r{#{markdown_formatted_list}})

          subject
        end
      end

      context 'with analytics instrumentation::review pending label' do
        let(:mr_labels) { ['analytics instrumentation::review pending'] }

        include_examples "doesn't add new labels"
      end

      context 'with analytics instrumentation::approved label' do
        let(:mr_labels) { ['analytics instrumentation::approved'] }

        include_examples "doesn't add new labels"
      end

      context 'with the analytics instrumentation label' do
        let(:has_analytics_instrumentation_label) { true }

        context 'with ci? false' do
          let(:ci_env) { false }

          include_examples "doesn't add new labels"
        end

        context 'with ci? true' do
          include_examples 'adds new labels'
        end
      end
    end
  end

  describe '#check_affected_scopes!' do
    let(:fixture_dir_glob) { Dir.glob(File.join('spec', 'tooling', 'fixtures', 'metrics', '*.rb')) }
    let(:changed_lines) { ['+  scope :active, -> { iwhere(email: Array(emails)) }'] }

    before do
      allow(Dir).to receive(:glob).and_return(fixture_dir_glob)
      allow(fake_helper).to receive(:markdown_list).with({ 'active' => fixture_dir_glob }).and_return('a')
    end

    context 'when a model was modified' do
      let(:modified_files) { ['app/models/super_user.rb'] }

      context 'when a scope is changed' do
        context 'and a metrics uses the affected scope' do
          it 'producing warning' do
            expect(analytics_instrumentation).to receive(:warn).with(%r{#{modified_files}})

            analytics_instrumentation.check_affected_scopes!
          end
        end

        context 'when no metrics using the affected scope' do
          let(:changed_lines) { ['+scope :foo, -> { iwhere(email: Array(emails)) }'] }

          it 'doesnt do anything' do
            expect(analytics_instrumentation).not_to receive(:warn)

            analytics_instrumentation.check_affected_scopes!
          end
        end
      end
    end

    context 'when an unrelated model with matching scope was modified' do
      let(:modified_files) { ['app/models/post_box.rb'] }

      it 'doesnt do anything' do
        expect(analytics_instrumentation).not_to receive(:warn)

        analytics_instrumentation.check_affected_scopes!
      end
    end

    context 'when models arent modified' do
      let(:modified_files) { ['spec/app/models/user_spec.rb'] }

      it 'doesnt do anything' do
        expect(analytics_instrumentation).not_to receive(:warn)

        analytics_instrumentation.check_affected_scopes!
      end
    end
  end

  describe '#check_usage_data_insertions!' do
    context 'when usage_data.rb is modified' do
      let(:modified_files) { ['lib/gitlab/usage_data.rb'] }

      before do
        allow(fake_helper).to receive(:changed_lines).with("lib/gitlab/usage_data.rb").and_return(changed_lines)
      end

      context 'and has insertions' do
        let(:changed_lines) { ['+ ci_runners: count(::Ci::CiRunner),'] }

        it 'produces warning' do
          expect(analytics_instrumentation).to receive(:warn).with(/usage_data\.rb has been deprecated/)

          analytics_instrumentation.check_usage_data_insertions!
        end
      end

      context 'and changes are not insertions' do
        let(:changed_lines) { ['- ci_runners: count(::Ci::CiRunner),'] }

        it 'doesnt do anything' do
          expect(analytics_instrumentation).not_to receive(:warn)

          analytics_instrumentation.check_usage_data_insertions!
        end
      end
    end

    context 'when usage_data.rb is not modified' do
      context 'and another file has insertions' do
        let(:modified_files) { ['tooling/danger/analytics_instrumentation.rb'] }

        it 'doesnt do anything' do
          expect(fake_helper).to receive(:changed_lines).with("lib/gitlab/usage_data.rb").and_return([])
          allow(fake_helper).to receive(:changed_lines).with("tooling/danger/analytics_instrumentation.rb").and_return(["+ Inserting"])

          expect(analytics_instrumentation).not_to receive(:warn)

          analytics_instrumentation.check_usage_data_insertions!
        end
      end
    end
  end

  describe '#check_deprecated_data_sources!' do
    subject(:check_data_source) { analytics_instrumentation.check_deprecated_data_sources! }

    before do
      allow(fake_helper).to receive(:added_files).and_return([added_file])
      allow(fake_helper).to receive(:changed_lines).with(added_file).and_return(changed_lines)
      allow(analytics_instrumentation).to receive(:project_helper).and_return(fake_project_helper)
      allow(analytics_instrumentation.project_helper).to receive(:file_lines).and_return(changed_lines.map { |line| line.delete_prefix('+') })
    end

    context 'when no metric definitions were modified' do
      let(:added_file) { 'app/models/user.rb' }
      let(:changed_lines) { ['+ data_source: redis,'] }

      it 'does not trigger warning' do
        expect(analytics_instrumentation).not_to receive(:markdown)

        check_data_source
      end
    end

    context 'when metrics fields were modified' do
      let(:added_file) { 'config/metrics/count7_d/example_metric.yml' }

      [:redis, :redis_hll].each do |source|
        context "when source is #{source}" do
          let(:changed_lines) { ["+ data_source: #{source}"] }
          let(:template) do
            <<~SUGGEST_COMMENT
              ```suggestion
              data_source: internal_events
              ```

              %<message>s
            SUGGEST_COMMENT
          end

          it 'issues a warning' do
            expected_comment = format(template, message: Tooling::Danger::AnalyticsInstrumentation::CHANGE_DEPRECATED_DATA_SOURCE_MESSAGE)
            expect(analytics_instrumentation).to receive(:markdown).with(expected_comment.strip, file: added_file, line: 1)

            check_data_source
          end
        end
      end

      context 'when neither redis nor redis_hll used as a data_source' do
        let(:changed_lines) { ['+ data_source: database,'] }

        it 'does not issue a warning' do
          expect(analytics_instrumentation).not_to receive(:markdown)

          check_data_source
        end
      end
    end
  end

  describe '#check_removed_metric_fields!' do
    let(:file_lines) do
      file_diff.map { |line| line.delete_prefix('+') }
    end

    let(:milestone) { { 'title' => '17.1' } }
    let(:filename) { 'config/metrics/new_metric.yml' }
    let(:mr_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/1' }

    subject(:check_removed_metric_fields) { analytics_instrumentation.check_removed_metric_fields! }

    before do
      allow(fake_project_helper).to receive(:file_lines).with(filename).and_return(file_lines)
      allow(fake_helper).to receive(:modified_files).and_return([filename])
      allow(fake_helper).to receive(:changed_lines).with(filename).and_return(file_diff)
      allow(fake_helper).to receive(:mr_web_url).and_return(mr_url)
      allow(fake_helper).to receive(:mr_milestone).and_return(milestone)
      allow(analytics_instrumentation).to receive(:project_helper).and_return(fake_project_helper)
    end

    context 'when metric was removed' do
      context 'and removed_by_url is missing' do
        let(:file_diff) do
          [
            "+---",
            "+status: removed",
            "+milestone_removed: '#{milestone['title']}'"
          ]
        end

        it 'adds suggestions' do
          template = <<~SUGGEST_COMMENT
            ```suggestion
            status: removed
            removed_by_url: %<mr_url>s
            ```
          SUGGEST_COMMENT

          expected_format = format(template, mr_url: mr_url)

          expect(analytics_instrumentation).to receive(:markdown).with(expected_format, file: filename, line: 2)

          check_removed_metric_fields
        end
      end

      context 'and milestone_removed is missing' do
        let(:file_diff) do
          [
            "+---",
            "+status: removed",
            "+removed_by_url: #{mr_url}"
          ]
        end

        context 'when milestone is set for the MR' do
          it 'adds suggestions' do
            template = <<~SUGGEST_COMMENT
            ```suggestion
            status: removed
            milestone_removed: '%<milestone>s'
            ```
            SUGGEST_COMMENT

            expected_format = format(template, milestone: milestone['title'])

            expect(analytics_instrumentation).to receive(:markdown).with(expected_format, file: filename, line: 2)

            check_removed_metric_fields
          end
        end

        context 'when milestone is not set for the MR' do
          let(:milestone) { nil }

          it 'adds suggestions with placeholder text and a comment' do
            template = <<~SUGGEST_COMMENT
            ```suggestion
            status: removed
            milestone_removed: '[PLEASE SET MILESTONE]'
            ```
            SUGGEST_COMMENT

            expected_format = format("#{template}\nPlease set the `milestone_removed` value manually")

            expect(analytics_instrumentation).to receive(:markdown).with(expected_format, file: filename, line: 2)

            check_removed_metric_fields
          end
        end
      end

      context 'and both removed_by_url and milestone_removed are missing' do
        let(:file_diff) do
          [
            "+---",
            "+status: removed"
          ]
        end

        it 'adds suggestions' do
          template = <<~SUGGEST_COMMENT
            ```suggestion
            status: removed
            removed_by_url: %<mr_url>s
            milestone_removed: '%<milestone>s'
            ```
          SUGGEST_COMMENT

          expected_format = format(template, mr_url: mr_url, milestone: milestone['title'])

          expect(analytics_instrumentation).to receive(:markdown).with(expected_format, file: filename, line: 2)

          check_removed_metric_fields
        end
      end

      context 'and both removed_by_url and milestone_removed are present' do
        let(:file_diff) do
          [
            "+---",
            "+status: removed",
            "+removed_by_url: #{mr_url}",
            "+milestone_removed: '#{milestone['title']}'"
          ]
        end

        it 'does not add suggestions' do
          expect(analytics_instrumentation).not_to receive(:markdown)

          check_removed_metric_fields
        end
      end
    end

    context 'when metric was not removed' do
      let(:file_diff) do
        [
          "+---",
          "+status: active",
          "+removed_by_url: #{mr_url}",
          "+milestone_removed: '#{milestone['title']}'"
        ]
      end

      it 'does not add suggestions' do
        expect(analytics_instrumentation).not_to receive(:markdown)

        check_removed_metric_fields
      end
    end
  end

  describe '#warn_about_migrated_redis_keys_specs!' do
    let(:redis_hll_file) { 'lib/gitlab/usage_data_counters/hll_redis_key_overrides.yml' }
    let(:total_counter_file) { 'lib/gitlab/usage_data_counters/total_counter_redis_key_overrides.yml' }

    subject(:check_redis_keys_files_overrides) { analytics_instrumentation.warn_about_migrated_redis_keys_specs! }

    before do
      allow(fake_helper).to receive(:changed_lines).with(redis_hll_file).and_return([file_diff_hll])
      allow(fake_helper).to receive(:changed_lines).with(total_counter_file).and_return([file_diff_total])
    end

    context 'when new keys added to overrides files' do
      let(:file_diff_hll) { "+user_viewed_cluster_configuration-user: user_viewed_cluster_configuration" }
      let(:file_diff_total) { "+user_viewed_cluster_configuration-user: USER_VIEWED_CLUSTER_CONFIGURATION" }

      it 'adds suggestion to add specs' do
        expect(analytics_instrumentation).to receive(:warn)

        check_redis_keys_files_overrides
      end
    end

    context 'when no new keys added to overrides files' do
      let(:file_diff_hll) { "-user_viewed_cluster_configuration-user: user_viewed_cluster_configuration" }
      let(:file_diff_total) { "-user_viewed_cluster_configuration-user: USER_VIEWED_CLUSTER_CONFIGURATION" }

      it 'adds suggestion to add specs' do
        expect(analytics_instrumentation).not_to receive(:warn)

        check_redis_keys_files_overrides
      end
    end
  end
end
