# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/saas_feature'

RSpec.describe Tooling::Danger::SaasFeature, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  subject(:saas_feature) { fake_danger.new(helper: fake_helper) }

  describe '#files' do
    let(:feature_flag_paths) do
      [
        'ee/config/saas_features/entry.yml'
      ]
    end

    let(:other_file_paths) do
      %w[app/models/model.rb app/assets/javascripts/file.js]
    end

    shared_examples 'an array of Found objects' do |change_type|
      it 'returns an array of Found objects' do
        found_files = saas_feature.files(change_type: change_type)

        expect(found_files).to contain_exactly(an_instance_of(described_class::Found))
        expect(found_files.map(&:path)).to eq(feature_flag_paths)
      end
    end

    shared_examples 'an empty array' do |change_type|
      it 'returns an array of Found objects' do
        expect(saas_feature.files(change_type: change_type)).to be_empty
      end
    end

    describe 'retrieves added files' do
      context 'when added files contain SaaS feature files' do
        let(:added_files) { feature_flag_paths + other_file_paths }

        include_examples 'an array of Found objects', :added
      end

      context 'when added files does not contain SaaS feature files' do
        let(:added_files) { other_file_paths }

        include_examples 'an empty array', :added
      end
    end

    describe 'retrieves modified files' do
      context 'when modified files contain SaaS feature files' do
        let(:modified_files) { feature_flag_paths }

        include_examples 'an array of Found objects', :modified
      end

      context 'when modified files does not contain SaaS feature files' do
        let(:modified_files) { other_file_paths }

        include_examples 'an empty array', :modified
      end
    end

    describe 'retrieves deleted files' do
      context 'when deleted files contain SaaS feature files' do
        let(:deleted_files) { feature_flag_paths }

        include_examples 'an array of Found objects', :deleted
      end

      context 'when deleted files does not contain SaaS feature files' do
        let(:deleted_files) { other_file_paths }

        include_examples 'an empty array', :deleted
      end
    end
  end

  describe described_class::Found do
    let(:path) { 'ee/config/saas_features/entry.yml' }
    let(:group) { 'group::source code' }
    let(:yaml) do
      {
        'group' => group,
        'introduced_by_url' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/2',
        'milestone' => '15.9',
        'name' => 'entry'
      }
    end

    let(:raw_yaml) { YAML.dump(yaml) }

    subject(:found) { described_class.new(path) }

    before do
      allow(File).to receive(:read).and_call_original
      expect(File).to receive(:read).with(path).and_return(raw_yaml) # rubocop:disable RSpec/ExpectInHook
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
          expect(found.group_match_mr_label?(group)).to eq true
          expect(found.group_match_mr_label?('group::source code')).to eq false
        end
      end

      context 'when group is not nil' do
        it 'is true only if MR has the same group label' do
          expect(found.group_match_mr_label?(group)).to eq true
          expect(found.group_match_mr_label?(nil)).to eq false
          expect(found.group_match_mr_label?('group::authentication and authorization')).to eq false
        end
      end
    end
  end
end
