# frozen_string_literal: true

require 'fast_spec_helper'
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
    let(:yaml) do
      {
        'group' => group,
        'default_enabled' => true,
        'rollout_issue_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/1',
        'introduced_by_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/2',
        'milestone' => '15.9',
        'type' => 'development',
        'name' => 'entry'
      }
    end

    let(:raw_yaml) { YAML.dump(yaml) }

    subject(:found) { described_class.new(feature_flag_path) }

    before do
      allow(File).to receive(:read).and_call_original
      expect(File).to receive(:read).with(feature_flag_path).and_return(raw_yaml)
    end

    described_class::ATTRIBUTES.each do |attribute|
      describe "##{attribute}" do
        it 'returns value from the YAML' do
          expect(found.public_send(attribute)).to eq(yaml[attribute])
        end
      end
    end

    describe '#raw' do
      it 'returns the raw YAML' do
        expect(found.raw).to eq(raw_yaml)
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
  end
end
