# frozen_string_literal: true

require 'spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/feature_flag'

RSpec.describe Tooling::Danger::FeatureFlag, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  before do
    allow(File).to receive(:read).and_return(YAML.dump({}))
  end

  subject(:feature_flag) { fake_danger.new(helper: fake_helper) }

  describe '#feature_flag_files' do
    let(:feature_flag_files) do
      [
        'config/feature_flags/development/entry.yml',
        'ee/config/feature_flags/ops/entry.yml'
      ]
    end

    let(:other_files) do
      [
        'app/models/model.rb',
        'app/assets/javascripts/file.js',
        'ee/config/feature_flags/ops/entry.patch'
      ]
    end

    shared_examples 'an array of Found objects' do |change_type|
      it 'returns an array of Found objects' do
        expect(feature_flag.feature_flag_files(danger_helper: fake_helper, change_type: change_type)).to contain_exactly(an_instance_of(described_class::Found), an_instance_of(described_class::Found))
        expect(feature_flag.feature_flag_files(danger_helper: fake_helper, change_type: change_type).map(&:path)).to eq(feature_flag_files)
      end
    end

    shared_examples 'an empty array' do |change_type|
      it 'returns an array of Found objects' do
        expect(feature_flag.feature_flag_files(danger_helper: fake_helper, change_type: change_type)).to be_empty
      end
    end

    describe 'retrieves added feature flag files' do
      context 'with added added feature flag files' do
        let(:added_files) { feature_flag_files }

        include_examples 'an array of Found objects', :added
      end

      context 'without added added feature flag files' do
        let(:added_files) { other_files }

        include_examples 'an empty array', :added
      end
    end

    describe 'retrieves modified feature flag files' do
      context 'with modified modified feature flag files' do
        let(:modified_files) { feature_flag_files }

        include_examples 'an array of Found objects', :modified
      end

      context 'without modified modified feature flag files' do
        let(:modified_files) { other_files }

        include_examples 'an empty array', :modified
      end
    end

    describe 'retrieves deleted feature flag files' do
      context 'with deleted deleted feature flag files' do
        let(:deleted_files) { feature_flag_files }

        include_examples 'an array of Found objects', :deleted
      end

      context 'without deleted deleted feature flag files' do
        let(:deleted_files) { other_files }

        include_examples 'an empty array', :deleted
      end
    end
  end

  describe described_class::Found do
    let(:feature_flag_path) { 'config/feature_flags/development/entry.yml' }
    let(:name) { 'entry' }
    let(:group) { 'group::source code' }
    let(:default_enabled) { false }
    let(:feature_issue_url) { 'https://gitlab.com/gitlab-org/gitlab/-/issues/1' }
    let(:introduced_by_url) { 'https://gitlab.com/gitlab-org/gitlab/-/merge_requests/3' }
    let(:rollout_issue_url) { 'https://gitlab.com/gitlab-org/gitlab/-/issues/2' }
    let(:milestone) { '15.9' }
    let(:yaml) do
      {
        'name' => name,
        'default_enabled' => default_enabled,
        'feature_issue_url' => feature_issue_url,
        'rollout_issue_url' => rollout_issue_url,
        'introduced_by_url' => introduced_by_url,
        'milestone' => milestone,
        'group' => group,
        'type' => 'beta'
      }
    end

    let(:raw_yaml) { YAML.dump(yaml) }

    subject(:found) { described_class.build(feature_flag_path) }

    before do
      allow(File).to receive(:read).with(feature_flag_path).and_return(raw_yaml)
    end

    describe '.build' do
      it { expect(found).to be_a(described_class) }

      context 'when given path does not exist' do
        before do
          allow(File).to receive(:read).with(feature_flag_path).and_raise("File not found")
        end

        it { expect(found.lines).to be_nil }
      end

      context 'when YAML is invalid' do
        let(:raw_yaml) { 'foo bar' }

        it { expect(found.lines).to be_nil }
      end
    end

    describe '#valid?' do
      context 'when name is nil' do
        let(:name) { nil }

        it { expect(found.valid?).to eq(false) }
      end

      context 'when name is not nil' do
        it { expect(found.valid?).to eq(true) }
      end
    end

    describe '#missing_group?' do
      context 'when group is nil' do
        let(:group) { nil }

        it { expect(found.missing_group?).to eq(true) }
      end

      context 'when group is not nil' do
        it { expect(found.missing_group?).to eq(false) }
      end
    end

    describe '#missing_feature_issue_url?' do
      context 'when feature_issue_url is nil' do
        let(:feature_issue_url) { nil }

        it { expect(found.missing_feature_issue_url?).to eq(true) }
      end

      context 'when feature_issue_url is not nil' do
        it { expect(found.missing_feature_issue_url?).to eq(false) }
      end
    end

    describe '#missing_introduced_by_url?' do
      context 'when introduced_by_url is nil' do
        let(:introduced_by_url) { nil }

        it { expect(found.missing_introduced_by_url?).to eq(true) }
      end

      context 'when introduced_by_url is not nil' do
        it { expect(found.missing_introduced_by_url?).to eq(false) }
      end
    end

    describe '#missing_rollout_issue_url?' do
      context 'when rollout_issue_url is nil' do
        let(:rollout_issue_url) { nil }

        it { expect(found.missing_rollout_issue_url?).to eq(true) }
      end

      context 'when rollout_issue_url is not nil' do
        it { expect(found.missing_rollout_issue_url?).to eq(false) }
      end
    end

    describe '#missing_milestone?' do
      context 'when milestone is nil' do
        let(:milestone) { nil }

        it { expect(found.missing_milestone?).to eq(true) }
      end

      context 'when milestone is not nil' do
        it { expect(found.missing_milestone?).to eq(false) }
      end
    end

    describe '#default_enabled?' do
      context 'when default_enabled is nil' do
        let(:default_enabled) { nil }

        it { expect(found.default_enabled?).to eq(false) }
      end

      context 'when default_enabled is false' do
        let(:default_enabled) { false }

        it { expect(found.default_enabled?).to eq(false) }
      end

      context 'when default_enabled is true' do
        let(:default_enabled) { true }

        it { expect(found.default_enabled?).to eq(true) }
      end
    end

    describe '#group_match_mr_label?' do
      context 'when group is nil' do
        let(:group) { nil }

        it 'is true only if MR has no group label' do
          expect(found.group_match_mr_label?(nil)).to eq true
          expect(found.group_match_mr_label?('group::source code')).to eq false
        end
      end

      context 'when group is not nil' do
        it 'is true only if MR has the same group label' do
          expect(found.group_match_mr_label?(group)).to eq true
          expect(found.group_match_mr_label?('group::authentication')).to eq false
        end
      end
    end

    describe '#find_line_index' do
      context 'when line is found' do
        let(:group) { nil }

        it { expect(found.find_line_index("name: #{name}")).to eq(1) }
      end

      context 'when line is not found' do
        it { expect(found.find_line_index("foo")).to be_nil }
      end
    end
  end
end
