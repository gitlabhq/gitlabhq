# frozen_string_literal: true

require 'spec_helper'
require './keeps/delete_old_feature_flags'

RSpec.describe Keeps::DeleteOldFeatureFlags, feature_category: :tooling do
  let(:groups) do
    {
      foo: {
        label: 'group::foo',
        backend_engineers: ['@john_doe']
      }
    }
  end

  let(:feature_flag_name) { 'feature_flag_name' }
  let(:feature_flag_milestone) { '15.8' }
  let(:feature_flag_file) do
    Tempfile.new('feature_flag.yml').tap do |file|
      file.open
      file.write({
        name: feature_flag_name,
        milestone: feature_flag_milestone,
        group: groups.dig(:foo, :label)
      }.to_yaml)
      file.rewind
    end
  end

  let(:milestones_helper) { instance_double(Keeps::Helpers::Milestones) }

  subject(:keep) { described_class.new }

  before do
    stub_request(:get, Keeps::Helpers::Groups::GROUPS_JSON_URL).to_return(status: 200, body: groups.to_json)

    allow(keep).to receive(:all_feature_flag_files).and_return([feature_flag_file.path])
    allow(keep).to receive(:milestones_helper).and_return(milestones_helper)

    allow(milestones_helper)
      .to receive(:before_cuttoff?).with(milestone: feature_flag_milestone, milestones_ago: 12)
      .and_return(true)
  end

  after do
    feature_flag_file.close
  end

  describe '#each_change' do
    let(:expected_change) { instance_double(Gitlab::Housekeeper::Change) }

    it 'returns a Gitlab::Housekeeper::Change', :aggregate_failures do
      expect(Gitlab::Housekeeper::Shell).to receive(:execute).with(
        'git', 'grep', '--heading', '--line-number', '--break',
        feature_flag_name, '--', ':^locale/', ':^db/structure.sql'
      )

      expect(FileUtils).to receive(:rm).with(feature_flag_file.path)

      actual_changes = keep.each_change(&:itself)

      expect(actual_changes.size).to eq(1)

      actual_change = actual_changes.first
      expect(actual_change).to be_a(Gitlab::Housekeeper::Change)
      expect(actual_change.changelog_type).to eq('removed')
      expect(actual_change.title).to eq("Delete the `#{feature_flag_name}` feature flag")
      expect(actual_change.identifiers).to eq([described_class.name.demodulize, feature_flag_name])
      expect(actual_change.changed_files).to eq([feature_flag_file.path])
      expect(actual_change.reviewers).to eq(['@john_doe'])
      expect(actual_change.labels).to eq(['maintenance::removal', 'feature flag', groups.dig(:foo, :label)])
    end
  end
end
