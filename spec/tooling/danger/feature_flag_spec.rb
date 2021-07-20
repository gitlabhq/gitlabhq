# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/feature_flag'

RSpec.describe Tooling::Danger::FeatureFlag do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

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
        'app/assets/javascripts/file.js'
      ]
    end

    shared_examples 'an array of Found objects' do |change_type|
      it 'returns an array of Found objects' do
        expect(feature_flag.feature_flag_files(change_type: change_type)).to contain_exactly(an_instance_of(described_class::Found), an_instance_of(described_class::Found))
        expect(feature_flag.feature_flag_files(change_type: change_type).map(&:path)).to eq(feature_flag_files)
      end
    end

    shared_examples 'an empty array' do |change_type|
      it 'returns an array of Found objects' do
        expect(feature_flag.feature_flag_files(change_type: change_type)).to be_empty
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
    let(:group) { 'group::source code' }
    let(:raw_yaml) do
      YAML.dump(
        'group' => group,
        'default_enabled' => true,
        'rollout_issue_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/1'
      )
    end

    subject(:found) { described_class.new(feature_flag_path) }

    before do
      allow(File).to receive(:read).and_call_original
      expect(File).to receive(:read).with(feature_flag_path).and_return(raw_yaml)
    end

    describe '#raw' do
      it 'returns the raw YAML' do
        expect(found.raw).to eq(raw_yaml)
      end
    end

    describe '#group' do
      it 'returns the group found in the YAML' do
        expect(found.group).to eq(group)
      end
    end

    describe '#default_enabled' do
      it 'returns the default_enabled found in the YAML' do
        expect(found.default_enabled).to eq(true)
      end
    end

    describe '#rollout_issue_url' do
      it 'returns the rollout_issue_url found in the YAML' do
        expect(found.rollout_issue_url).to eq('https://gitlab.com/gitlab-org/gitlab/-/issues/1')
      end
    end

    describe '#group_match_mr_label?' do
      subject(:result) { found.group_match_mr_label?(mr_group_label) }

      context 'when MR labels match FF group' do
        let(:mr_group_label) { 'group::source code' }

        specify { expect(result).to eq(true) }
      end

      context 'when MR labels does not match FF group' do
        let(:mr_group_label) { 'group::access' }

        specify { expect(result).to eq(false) }
      end

      context 'when group is nil' do
        let(:group) { nil }

        context 'and MR has no group label' do
          let(:mr_group_label) { nil }

          specify { expect(result).to eq(true) }
        end

        context 'and MR has a group label' do
          let(:mr_group_label) { 'group::source code' }

          specify { expect(result).to eq(false) }
        end
      end
    end
  end
end
