# frozen_string_literal: true

require 'spec_helper'
require './keeps/delete_old_feature_flags'

RSpec.describe Keeps::DeleteOldFeatureFlags, feature_category: :tooling do
  let(:groups) do
    {
      foo: {
        label: 'group::global search',
        backend_engineers: ['@john_doe']
      }
    }
  end

  let(:feature_flag_name) { 'feature_flag_name' }
  let(:tmp_dir) { Pathname(Dir.mktmpdir) }
  let(:feature_flag_milestone) { '15.8' }
  let(:feature_flag_file) do
    file_path = tmp_dir.join('feature_flag.yml')

    File.write(file_path, {
      name: feature_flag_name,
      milestone: feature_flag_milestone,
      rollout_issue: 'issue_url',
      group: groups.dig(:foo, :label),
      default_enabled: true
    }.to_yaml)

    file_path.to_s
  end

  let(:milestones_helper) { instance_double(Keeps::Helpers::Milestones) }

  subject(:keep) { described_class.new }

  before do
    stub_request(:get, Keeps::Helpers::Groups::GROUPS_JSON_URL).to_return(status: 200, body: groups.to_json)
    stub_request(:get, format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123'))
      .to_return(status: 200, body: { labels: [] }.to_json)

    allow(keep).to receive(:all_feature_flag_files).and_return([feature_flag_file])
    allow(keep).to receive(:milestones_helper).and_return(milestones_helper)
    allow(keep).to receive(:can_remove_ff?).and_return(true)

    reviewer_roulette = instance_double(Keeps::Helpers::ReviewerRoulette, reviewer_available?: true)
    allow_next_instance_of(Keeps::Helpers::Groups) do |keeps_groups_helper|
      allow(keeps_groups_helper).to receive(:roulette).and_return(reviewer_roulette)
    end

    allow(milestones_helper)
      .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
        milestones_ago: described_class::CUTOFF_MILESTONE_FOR_ENABLED_FLAG)
      .and_return(true)
    allow(milestones_helper)
      .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
        milestones_ago: described_class::CUTOFF_MILESTONE_FOR_DISABLED_FLAG)
      .and_return(true)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe '#can_remove_ff?' do
    let(:feature_flag) do
      instance_double(
        Feature::Definition,
        name: feature_flag_name,
        milestone: feature_flag_milestone,
        rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
        default_enabled: false,
        group: groups.dig(:foo, :label),
        path: feature_flag_file,
        intended_to_rollout_by: nil
      )
    end

    let(:identifiers) { ['DeleteOldFeatureFlags', feature_flag_name] }

    before do
      allow(keep).to receive(:can_remove_ff?).and_call_original
      allow(keep).to receive(:logger).and_return(double.as_null_object)
      allow(keep).to receive(:matches_filter_identifiers?).and_return(true)
      allow(keep).to receive(:feature_flag_rollout_issue_url).and_return(feature_flag.rollout_issue_url)
      allow(keep).to receive(:get_latest_feature_flag_status).and_return(:enabled)
    end

    context 'when milestone is nil' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: nil,
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: false,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: nil
        )
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end

    context 'when milestone is after cutoff for enabled flags' do
      before do
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_ENABLED_FLAG)
          .and_return(false)
      end

      it 'returns false for enabled flag' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end

    context 'when milestone is after cutoff for disabled flags' do
      before do
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_DISABLED_FLAG)
          .and_return(false)
      end

      it 'returns false for disabled flag' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :disabled)).to be false
      end
    end

    context 'when feature flag does not match filter identifiers' do
      before do
        allow(keep).to receive(:matches_filter_identifiers?).and_return(false)
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end

    context 'when feature flag is default enabled' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: feature_flag_milestone,
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: true,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: nil
        )
      end

      it 'returns true' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when latest feature flag status is nil' do
      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, nil)).to be false
      end
    end

    context 'when latest feature flag status is conditional' do
      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :conditional)).to be false
      end
    end

    context 'when all conditions are met for enabled flags' do
      it 'returns true' do
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_ENABLED_FLAG)
          .and_return(true)

        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when all conditions are met for disabled flags' do
      it 'returns true' do
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_DISABLED_FLAG)
          .and_return(true)

        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :disabled)).to be true
      end
    end

    describe '#parse_date' do
      it 'returns a date object for valid date strings' do
        expect(keep.send(:parse_date, '2023-01-01')).to eq(Date.new(2023, 1, 1))
      end

      it 'returns nil for invalid date strings' do
        expect(keep.send(:parse_date, '2020')).to be_nil
        expect(keep.send(:parse_date, 'invalid')).to be_nil
        expect(keep.send(:parse_date, 'February 31, 2023')).to be_nil
      end
    end

    context 'when feature flag has a future intended_to_rollout_by date' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: feature_flag_milestone,
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: false,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: (Time.zone.today + 30).to_s
        )
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end

    context 'when feature flag has a past intended_to_rollout_by date' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: feature_flag_milestone,
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: false,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: (Time.zone.today - 30).to_s
        )
      end

      it 'returns true when other conditions are met' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when feature flag has an invalid intended_to_rollout_by date' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: feature_flag_milestone,
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: false,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: '2020'
        )
      end

      # When parse_date returns nil for an invalid date, it passes through
      # the condition and allows removal
      it 'returns true when other conditions are met' do
        expect(keep.send(:parse_date, '2020')).to be_nil
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when feature flag has ready for removal label' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: nil, # This would normally fail validation
          rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123',
          default_enabled: false,
          group: groups.dig(:foo, :label),
          path: feature_flag_file,
          intended_to_rollout_by: (Time.zone.today + 30).to_s # Future date would normally fail validation
        )
      end

      before do
        stub_request(:get,
          format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123')
        ).to_return(status: 200, body: { labels: ['feature flag::ready for removal'] }.to_json)

        # Make milestone cutoff check fail to prove it's bypassed
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_ENABLED_FLAG)
          .and_return(false)
      end

      it 'bypasses rollout date, milestone, and cutoff checks and returns true' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when feature flag does not have ready for removal label' do
      before do
        stub_request(:get,
          format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123')
        ).to_return(status: 200, body: { labels: ['some other label'] }.to_json)

        # Make milestone cutoff check fail
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone,
            milestones_ago: described_class::CUTOFF_MILESTONE_FOR_ENABLED_FLAG)
          .and_return(false)
      end

      it 'respects milestone cutoff check and returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end
  end

  describe '#has_ready_for_removal_label?' do
    let(:feature_flag) do
      instance_double(
        Feature::Definition,
        name: feature_flag_name,
        rollout_issue_url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/123'
      )
    end

    before do
      allow(keep).to receive(:logger).and_return(double.as_null_object)
      allow(keep).to receive(:feature_flag_rollout_issue_url).and_return(feature_flag.rollout_issue_url)
    end

    context 'when rollout issue has ready for removal label' do
      before do
        stub_request(:get,
          format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123')
        ).to_return(status: 200, body: { labels: ['feature flag::ready for removal',
          'other label'] }.to_json)
      end

      it 'returns true' do
        expect(keep.send(:has_ready_for_removal_label?, feature_flag)).to be true
      end
    end

    context 'when rollout issue does not have ready for removal label' do
      before do
        stub_request(:get,
          format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123')
        ).to_return(status: 200, body: { labels: ['some other label'] }.to_json)
      end

      it 'returns false' do
        expect(keep.send(:has_ready_for_removal_label?, feature_flag)).to be false
      end
    end

    context 'when rollout issue URL is missing' do
      let(:feature_flag) do
        instance_double(
          Feature::Definition,
          name: feature_flag_name,
          milestone: feature_flag_milestone,
          rollout_issue_url: nil
        )
      end

      before do
        allow(keep).to receive(:feature_flag_rollout_issue_url).and_return('(missing URL)')
      end

      it 'returns false' do
        expect(keep.send(:has_ready_for_removal_label?, feature_flag)).to be false
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get,
          format(described_class::API_ISSUE_URL, project_path: 'gitlab-org%2Fgitlab', issue_iid: '123'))
          .to_return(status: 404)
      end

      it 'returns false' do
        expect(keep.send(:has_ready_for_removal_label?, feature_flag)).to be false
      end
    end
  end

  describe '#each_identified_change' do
    before do
      allow(keep).to receive(:can_remove_ff?).and_return(true)
    end

    context 'when we use ai to get the patch' do
      let(:expected_change) { instance_double(Gitlab::Housekeeper::Change) }
      let(:ai_helper) { instance_double(Keeps::Helpers::AiEditor) }

      before do
        allow(keep).to receive(:ai_helper).and_return(ai_helper)
        allow(keep).to receive(:files_mentioning_feature_flag).and_return(['app/controllers/feature_controller.rb'])
        allow(keep).to receive(:remove_feature_flag_prompts).and_return(
          instance_double(Keeps::Prompts::RemoveFeatureFlags, fetch: 'user message')
        )
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        allow(Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect).and_return(true)
      end

      it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
        allow(keep).to receive(:execute_grep).and_return("grep results")
        expect(FileUtils).to receive(:rm).with(feature_flag_file)

        actual_changes = []
        keep.each_identified_change do |change|
          keep.make_change!(change)
          actual_changes << change
        end

        expect(actual_changes.size).to eq(1)

        actual_change = actual_changes.first
        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.changelog_type).to eq('removed')
        expect(actual_change.title).to eq("Delete the `#{feature_flag_name}` feature flag")
        expect(actual_change.identifiers).to match_array([described_class.name.demodulize, feature_flag_name])
        expect(actual_change.reviewers).to match_array(['@john_doe'])
        expect(actual_change.labels).to match_array(['automation:feature-flag-removal', 'maintenance::removal',
          'feature flag', groups.dig(:foo, :label)])
        expect(actual_change.changed_files).to include(feature_flag_file)
        expect(actual_change.changed_files).to include('app/controllers/feature_controller.rb')
      end
    end

    context 'when we have feature flag patch path present' do
      let(:expected_change) { instance_double(Gitlab::Housekeeper::Change) }
      let(:feature_flag_patch_path) { feature_flag_file.sub(/.yml$/, '.patch') }

      before do
        File.write(feature_flag_patch_path, <<~DIFF)
        diff --git a/foobar.txt b/foobar.txt
        index 2ef267e25bd6..0fecdb8e98f3 100644
        --- a/foobar.txt
        +++ b/foobar.txt
        @@ -1 +1 @@
        -some content
        +some content updated
        DIFF
      end

      it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
        allow(keep).to receive(:execute_grep).and_return("grep results")
        expect(FileUtils).to receive(:rm).with(feature_flag_file)
        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with('git', 'apply', feature_flag_patch_path)
        expect(FileUtils).to receive(:rm).with(feature_flag_patch_path)

        actual_changes = []
        keep.each_identified_change do |change|
          keep.make_change!(change)
          actual_changes << change
        end

        expect(actual_changes.size).to eq(1)

        actual_change = actual_changes.first
        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.changelog_type).to eq('removed')
        expect(actual_change.title).to eq("Delete the `#{feature_flag_name}` feature flag")
        expect(actual_change.identifiers).to match_array([described_class.name.demodulize, feature_flag_name])
        expect(actual_change.changed_files).to match_array([feature_flag_file, feature_flag_patch_path, 'foobar.txt'])
        expect(actual_change.reviewers).to match_array(['@john_doe'])
        expect(actual_change.labels).to match_array(['automation:feature-flag-removal', 'maintenance::removal',
          'feature flag', groups.dig(:foo, :label)])
      end
    end
  end

  describe '#files_mentioning_feature_flag' do
    let(:logger) { instance_double(Gitlab::Housekeeper::Logger) }

    before do
      keep.instance_variable_set(:@logger, logger)
      allow(logger).to receive(:puts)
    end

    context 'when there are matching files' do
      it 'returns the list of files' do
        expect(keep).to receive(:find_files_with_pattern).with("feature.*#{feature_flag_name}").and_return(['file1.rb'])
        expect(keep).to receive(:find_files_with_pattern).with(
          "push_frontend_feature_flag.*#{feature_flag_name}"
        ).and_return(['file2.rb'])
        expect(keep).to receive(:find_files_with_pattern).with("glFeatures.*featureFlagName").and_return(['file3.js'])
        expect(keep).to receive(:find_files_with_pattern).with("gon.*featureFlagName").and_return([])
        expect(keep).to receive(:find_files_with_pattern).with("featureFlagName").and_return(['file4.vue'])
        expect(keep).to receive(:find_files_with_pattern).with("feature_flag_name").and_return([])

        result = keep.send(:files_mentioning_feature_flag, feature_flag_name)

        expect(result).to match_array(['file1.rb', 'file2.rb', 'file3.js', 'file4.vue'])
      end

      it 'makes the expected git grep calls to find relevant files' do
        camel_case_flag = feature_flag_name.camelize(:lower)

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', "feature.*#{feature_flag_name}",
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("file1.rb")

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', "push_frontend_feature_flag.*#{feature_flag_name}",
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("file2.rb")

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', "glFeatures.*#{camel_case_flag}",
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("file3.js")

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', "gon.*#{camel_case_flag}",
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("")

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', camel_case_flag,
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("file4.vue")

        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', feature_flag_name,
          '--', ':^locale/', ':^db/structure.sql'
        ).and_return("")

        result = keep.send(:files_mentioning_feature_flag, feature_flag_name)
        expect(result).to match_array(['file1.rb', 'file2.rb', 'file3.js', 'file4.vue'])
      end
    end

    context 'when there are no matching files' do
      it 'returns an empty array' do
        allow(keep).to receive(:find_files_with_pattern).and_return([])

        result = keep.send(:files_mentioning_feature_flag, feature_flag_name)

        expect(result).to eq([])
      end
    end

    context 'when there are duplicate files' do
      it 'returns unique file names' do
        camel_case_flag = feature_flag_name.camelize(:lower)
        expect(keep).to receive(:find_files_with_pattern).with("feature.*#{feature_flag_name}").and_return(['file1.rb'])
        expect(keep).to receive(:find_files_with_pattern).with(
          "push_frontend_feature_flag.*#{feature_flag_name}"
        ).and_return(['file1.rb'])
        expect(keep).to receive(:find_files_with_pattern)
          .with("glFeatures.*#{camel_case_flag}").and_return(['file2.js'])
        expect(keep).to receive(:find_files_with_pattern).with("gon.*#{camel_case_flag}").and_return([])
        expect(keep).to receive(:find_files_with_pattern).with(camel_case_flag).and_return(['file2.js'])
        expect(keep).to receive(:find_files_with_pattern).with(feature_flag_name).and_return([])

        result = keep.send(:files_mentioning_feature_flag, feature_flag_name)

        expect(result).to match_array(['file1.rb', 'file2.js'])
      end
    end
  end

  describe '#find_files_with_pattern' do
    let(:logger) { instance_double(Gitlab::Housekeeper::Logger) }

    before do
      keep.instance_variable_set(:@logger, logger)
      allow(logger).to receive(:puts)
    end

    context 'when git grep finds files' do
      it 'returns the list of files' do
        expect(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', 'search_pattern', '--', ':^locale/', ':^db/structure.sql')
          .and_return("file1.rb\nfile2.rb")

        result = keep.send(:find_files_with_pattern, 'search_pattern')

        expect(result).to eq(['file1.rb', 'file2.rb'])
      end
    end

    context 'when git grep returns empty string' do
      it 'returns an empty array' do
        expect(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', 'search_pattern', '--', ':^locale/', ':^db/structure.sql')
          .and_return("")

        result = keep.send(:find_files_with_pattern, 'search_pattern')

        expect(result).to eq([])
      end
    end

    context 'when git grep returns nil' do
      it 'returns an empty array' do
        expect(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', 'search_pattern', '--', ':^locale/', ':^db/structure.sql')
          .and_return(nil)

        result = keep.send(:find_files_with_pattern, 'search_pattern')

        expect(result).to eq([])
      end
    end

    context 'when git grep raises an error' do
      it 'logs the error and returns an empty array' do
        expect(Gitlab::Housekeeper::Shell).to receive(:execute)
          .with('git', 'grep', '--name-only', 'search_pattern', '--', ':^locale/', ':^db/structure.sql')
          .and_raise(Gitlab::Housekeeper::Shell::Error)

        expect(logger).to receive(:puts).with("No files found for pattern: search_pattern")

        result = keep.send(:find_files_with_pattern, 'search_pattern')

        expect(result).to eq([])
      end
    end
  end

  describe '#apply_patch' do
    let(:feature_flag) do
      instance_double(
        Feature::Definition,
        name: feature_flag_name,
        path: feature_flag_file
      )
    end

    let(:patch_path) { feature_flag_file.sub(/.yml$/, '.patch') }
    let(:expected_files) { [patch_path, 'changed_file.rb'] }

    it 'executes git apply with the correct patch file' do
      change = instance_double(Gitlab::Housekeeper::Change)

      allow(keep).to receive(:patch_path).with(feature_flag).and_return(patch_path)
      allow(keep).to receive(:extract_changed_files_from_patch).with(feature_flag).and_return(['changed_file.rb'])

      expect(change).to receive(:changed_files).at_least(:once).and_return([])
      expect(change).to receive(:changed_files=).with(expected_files)

      expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
        'git', 'apply', patch_path
      ).and_return(true)

      expect(FileUtils).to receive(:rm).with(patch_path)

      result = keep.send(:apply_patch, feature_flag, change)
      expect(result).to be true
    end

    it 'returns false when git apply fails' do
      change = instance_double(Gitlab::Housekeeper::Change)

      allow(keep).to receive(:patch_path).with(feature_flag).and_return(patch_path)
      allow(keep).to receive(:extract_changed_files_from_patch).with(feature_flag).and_return(['changed_file.rb'])

      expect(change).to receive(:changed_files).at_least(:once).and_return([])
      expect(change).to receive(:changed_files=).with(expected_files)

      expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
        'git', 'apply', patch_path
      ).and_raise(Gitlab::Housekeeper::Shell::Error)

      result = keep.send(:apply_patch, feature_flag, change)
      expect(result).to be false
    end
  end

  describe '#feature_flag_grep' do
    before do
      allow(keep).to receive(:git_patterns).with(feature_flag_name).and_return(
        %w[pattern1 pattern2]
      )
    end

    it 'collects grep results from all patterns' do
      expect(keep).to receive(:execute_grep).with("pattern1").and_return("result1\n")
      expect(keep).to receive(:execute_grep).with("pattern2").and_return("result2\n")

      result = keep.send(:feature_flag_grep, feature_flag_name)

      expect(result).to include("result1\n", "result2\n")
    end

    it 'handles nil results gracefully' do
      expect(keep).to receive(:execute_grep).with("pattern1").and_return(nil)
      expect(keep).to receive(:execute_grep).with("pattern2").and_return("result2")

      result = keep.send(:feature_flag_grep, feature_flag_name)

      expect(result).to eq("result2\n")
    end
  end

  describe '#execute_grep' do
    it 'calls git grep with the given pattern' do
      pattern = "feature.*#{feature_flag_name}"

      expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
        'git', 'grep', '--heading', '--line-number', '--break',
        pattern, '--', ':^locale/', ':^db/structure.sql'
      ).and_return("grep results")

      result = keep.send(:execute_grep, pattern)
      expect(result).to eq("grep results")
    end

    it 'returns empty string when git grep raises an error' do
      pattern = "feature.*#{feature_flag_name}"

      expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
        'git', 'grep', '--heading', '--line-number', '--break',
        pattern, '--', ':^locale/', ':^db/structure.sql'
      ).and_raise(Gitlab::Housekeeper::Shell::Error)

      result = keep.send(:execute_grep, pattern)
      expect(result).to eq("")
    end
  end

  describe '#ai_patch' do
    let(:feature_flag) do
      instance_double(
        Feature::Definition,
        name: feature_flag_name
      )
    end

    let(:change) do
      instance_double(Gitlab::Housekeeper::Change, changed_files: [])
    end

    let(:ai_helper) { instance_double(Keeps::Helpers::AiEditor) }
    let(:logger) { instance_double(Gitlab::Housekeeper::Logger) }

    before do
      keep.instance_variable_set(:@logger, logger)
      allow(logger).to receive(:puts)
      allow(keep).to receive(:ai_helper).and_return(ai_helper)
      allow(keep).to receive(:get_latest_feature_flag_status).and_return(:enabled)
      allow(keep).to receive(:remove_feature_flag_prompts).and_return(
        instance_double(Keeps::Prompts::RemoveFeatureFlags, fetch: 'user message')
      )
    end

    context 'when files mentioning feature flag exceed MAX_FILES_LIMIT' do
      let(:files_list) { (1..81).map { |i| "file#{i}.rb" } }

      before do
        allow(keep).to receive(:files_mentioning_feature_flag).and_return(files_list)
      end

      it 'logs a message and returns false' do
        expect(logger).to receive(:puts).with(
          "More than #{described_class::MAX_FILES_LIMIT} are mentioning feature flag #{feature_flag_name}, Skipping."
        )

        result = keep.send(:ai_patch, feature_flag, change)

        expect(result).to be false
      end

      it 'does not attempt to process any files' do
        expect(ai_helper).not_to receive(:ask_for_and_apply_patch)

        keep.send(:ai_patch, feature_flag, change)
      end
    end

    context 'when files mentioning feature flag are within MAX_FILES_LIMIT' do
      let(:files_list) { %w[file1.rb file2.rb file3.rb] }

      before do
        allow(keep).to receive(:files_mentioning_feature_flag).and_return(files_list)
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        allow(Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
        changed_files_array = []
        allow(change).to receive(:changed_files).and_return(changed_files_array)
        allow(changed_files_array).to receive(:<<).and_return(changed_files_array)
      end

      it 'processes all files and returns true' do
        expect(ai_helper).to receive(:ask_for_and_apply_patch).exactly(3).times.and_return(true)

        result = keep.send(:ai_patch, feature_flag, change)

        expect(result).to be true
      end

      it 'adds processed files to change.changed_files' do
        changed_files_array = []
        allow(change).to receive(:changed_files).and_return(changed_files_array)
        expect(changed_files_array).to receive(:<<).with('file1.rb')
        expect(changed_files_array).to receive(:<<).with('file2.rb')
        expect(changed_files_array).to receive(:<<).with('file3.rb')

        keep.send(:ai_patch, feature_flag, change)
      end
    end

    context 'when exactly at MAX_FILES_LIMIT' do
      let(:files_list) { (1..80).map { |i| "file#{i}.rb" } }

      before do
        allow(keep).to receive(:files_mentioning_feature_flag).and_return(files_list)
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true)
        allow(Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
        changed_files_array = []
        allow(change).to receive(:changed_files).and_return(changed_files_array)
        allow(changed_files_array).to receive(:<<).and_return(changed_files_array)
      end

      it 'processes all files when exactly at the limit' do
        expect(ai_helper).to receive(:ask_for_and_apply_patch).exactly(80).times.and_return(true)

        result = keep.send(:ai_patch, feature_flag, change)

        expect(result).to be true
      end
    end

    context 'when some AI patches fail' do
      let(:files_list) { %w[file1.rb file2.rb file3.rb] }

      before do
        allow(keep).to receive(:files_mentioning_feature_flag).and_return(files_list)
        allow(Gitlab::Housekeeper::Shell).to receive(:rubocop_autocorrect)
        changed_files_array = []
        allow(change).to receive(:changed_files).and_return(changed_files_array)
        allow(changed_files_array).to receive(:<<).and_return(changed_files_array)
      end

      it 'logs failed files and returns false when some patches fail' do
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true, false, true)

        expect(logger).to receive(:puts).with("#{feature_flag_name}: Failed to apply AI patch for file2.rb, skipping")
        expect(logger).to receive(:puts).with("failed on 1 files")
        expect(logger).to receive(:puts).with("Failed files: file2.rb")

        result = keep.send(:ai_patch, feature_flag, change)

        expect(result).to be false
      end

      it 'returns true when all patches succeed' do
        allow(ai_helper).to receive(:ask_for_and_apply_patch).and_return(true, true, true)

        result = keep.send(:ai_patch, feature_flag, change)

        expect(result).to be true
      end
    end
  end

  describe '#each_feature_flag' do
    let(:tmp_dir) { Pathname(Dir.mktmpdir) }
    let(:feature_flag_file_1) { tmp_dir.join('feature_flag_1.yml') }
    let(:feature_flag_file_2) { tmp_dir.join('feature_flag_2.yml') }
    let(:feature_flag_file_3) { tmp_dir.join('feature_flag_3.yml') }

    before do
      # Create feature flags with different milestones
      File.write(feature_flag_file_1, {
        name: 'feature_flag_1',
        milestone: '15.10',
        rollout_issue: 'issue_url',
        group: 'group::foo',
        default_enabled: false
      }.to_yaml)

      File.write(feature_flag_file_2, {
        name: 'feature_flag_2',
        milestone: '15.8',
        rollout_issue: 'issue_url',
        group: 'group::foo',
        default_enabled: false
      }.to_yaml)

      File.write(feature_flag_file_3, {
        name: 'feature_flag_3',
        milestone: '15.9',
        rollout_issue: 'issue_url',
        group: 'group::foo',
        default_enabled: false
      }.to_yaml)

      allow(keep).to receive(:all_feature_flag_files).and_return([
        feature_flag_file_1.to_s,
        feature_flag_file_2.to_s,
        feature_flag_file_3.to_s
      ])
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it 'yields feature flags sorted by milestone' do
      yielded_flags = []

      keep.send(:each_feature_flag) do |feature_flag|
        yielded_flags << feature_flag
      end

      expect(yielded_flags.map(&:milestone)).to eq(['15.8', '15.9', '15.10'])
      expect(yielded_flags.map(&:name)).to eq(%w[feature_flag_2 feature_flag_3 feature_flag_1])
    end

    it 'rejects feature flags with nil milestone' do
      # Create a feature flag with nil milestone
      feature_flag_file_4 = tmp_dir.join('feature_flag_4.yml')
      File.write(feature_flag_file_4, {
        name: 'feature_flag_4',
        milestone: nil,
        rollout_issue: 'issue_url',
        group: 'group::foo',
        default_enabled: false
      }.to_yaml)

      allow(keep).to receive(:all_feature_flag_files).and_return([
        feature_flag_file_1.to_s,
        feature_flag_file_2.to_s,
        feature_flag_file_3.to_s,
        feature_flag_file_4.to_s
      ])

      yielded_flags = []

      keep.send(:each_feature_flag) do |feature_flag|
        yielded_flags << feature_flag
      end

      expect(yielded_flags.map(&:name)).to eq(%w[feature_flag_2 feature_flag_3 feature_flag_1])
      expect(yielded_flags.map(&:name)).not_to include('feature_flag_4')
    end
  end
end
