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

    allow(keep).to receive(:all_feature_flag_files).and_return([feature_flag_file])
    allow(keep).to receive(:milestones_helper).and_return(milestones_helper)
    allow(keep).to receive(:can_remove_ff?).and_return(true)

    allow(milestones_helper)
      .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone, milestones_ago: 12)
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
        path: feature_flag_file
      )
    end

    let(:identifiers) { ['DeleteOldFeatureFlags', feature_flag_name] }

    before do
      # Unstub can_remove_ff? for these tests
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
          path: feature_flag_file
        )
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
      end
    end

    context 'when milestone is after cutoff' do
      before do
        allow(milestones_helper)
          .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone, milestones_ago: 12)
          .and_return(false)
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
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
          path: feature_flag_file
        )
      end

      it 'returns true' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end

    context 'when feature flag is missing rollout issue URL' do
      before do
        allow(keep).to receive(:feature_flag_rollout_issue_url).and_return('(missing URL)')
      end

      it 'returns false' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be false
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

    context 'when all conditions are met' do
      it 'returns true' do
        expect(keep.send(:can_remove_ff?, feature_flag, identifiers, :enabled)).to be true
      end
    end
  end

  describe '#each_change' do
    before do
      allow(keep).to receive(:can_remove_ff?).and_return(true)
    end

    context 'when we use ai to get the patch' do
      let(:expected_change) { instance_double(Gitlab::Housekeeper::Change) }
      let(:ai_helper) { instance_double(Keeps::Helpers::AiEditor) }

      before do
        allow(keep).to receive(:ai_helper).and_return(ai_helper)
        allow(keep).to receive(:ask_for_and_apply_patch).and_return(true)
      end

      it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--name-only', '-i', "feature.*#{feature_flag_name}", '--', ':^locale/', ':^db/structure.sql'
        )
        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--heading', '--line-number', '--break',
          feature_flag_name, '--', ':^locale/', ':^db/structure.sql'
        )
        expect(FileUtils).to receive(:rm).with(feature_flag_file)

        actual_changes = keep.each_change(&:itself)

        expect(actual_changes.size).to eq(1)

        actual_change = actual_changes.first
        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.changelog_type).to eq('removed')
        expect(actual_change.title).to eq("Delete the `#{feature_flag_name}` feature flag")
        expect(actual_change.identifiers).to match_array([described_class.name.demodulize, feature_flag_name])
        expect(actual_change.reviewers).to match_array(['@john_doe'])
        expect(actual_change.labels).to match_array(['maintenance::removal', 'feature flag', groups.dig(:foo, :label)])
        expect(actual_change.changed_files).to match_array([feature_flag_file])
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
        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
          'git', 'grep', '--heading', '--line-number', '--break',
          feature_flag_name, '--', ':^locale/', ':^db/structure.sql'
        )
        expect(FileUtils).to receive(:rm).with(feature_flag_file)
        expect(Gitlab::Housekeeper::Shell).to receive(:execute).with('git', 'apply', feature_flag_patch_path)
        expect(FileUtils).to receive(:rm).with(feature_flag_patch_path)

        actual_changes = keep.each_change(&:itself)

        expect(actual_changes.size).to eq(1)

        actual_change = actual_changes.first
        expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
        expect(actual_change.changelog_type).to eq('removed')
        expect(actual_change.title).to eq("Delete the `#{feature_flag_name}` feature flag")
        expect(actual_change.identifiers).to match_array([described_class.name.demodulize, feature_flag_name])
        expect(actual_change.changed_files).to match_array([feature_flag_file, feature_flag_patch_path, 'foobar.txt'])
        expect(actual_change.reviewers).to match_array(['@john_doe'])
        expect(actual_change.labels).to match_array(['maintenance::removal', 'feature flag', groups.dig(:foo, :label)])
      end
    end
  end
end
