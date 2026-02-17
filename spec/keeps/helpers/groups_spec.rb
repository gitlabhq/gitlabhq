# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/groups'
require './keeps/helpers/reviewer_roulette'

RSpec.describe Keeps::Helpers::Groups, feature_category: :tooling do
  let(:roulette) { instance_double(Keeps::Helpers::ReviewerRoulette) }
  let(:groups) do
    {
      'tenant_scale' => {
        'name' => 'Tenant Scale',
        'section' => 'core_platform',
        'stage' => 'data_stores',
        'categories' => %w[cell groups_and_projects user_profile organization],
        'label' => 'group::tenant scale',
        'extra_labels' => [],
        'slack_channel' => 'g_tenant_scale',
        'engineers' => %w[fe1 fe2 be1 be2 be3 be4 be5 fs1],
        'backend_engineers' => %w[be1 be2 be3 be4 be5],
        'frontend_engineers' => %w[fe1 fe2],
        'fullstack_engineers' => %w[fs1],
        'triage_ops_config' => nil
      },
      'group_b' => {
        'name' => 'Group B',
        'section' => 'core_platform',
        'stage' => 'data_stores',
        'categories' => %w[category_b],
        'label' => 'group::group b',
        'extra_labels' => [],
        'slack_channel' => 'g_group_b',
        'engineers' => %w[],
        'triage_ops_config' => nil
      }
    }
  end

  before do
    # Reset singletons to create fresh instances
    Singleton.__init__(described_class)
    Singleton.__init__(Keeps::Helpers::ReviewerRoulette)

    allow(Keeps::Helpers::ReviewerRoulette).to receive(:instance).and_return(roulette)
    stub_request(:get, "https://about.gitlab.com/groups.json").to_return(status: 200, body: groups.to_json)
  end

  it 'is a singleton' do
    expect(described_class.instance).to be_a(Singleton)
  end

  describe '#group_for_feature_category' do
    let(:category) { 'organization' }

    subject(:group) { described_class.instance.group_for_feature_category(category) }

    it { is_expected.to eq(groups['tenant_scale']) }

    context 'when the category does not exist' do
      let(:category) { 'missing-category' }

      it { is_expected.to be_nil }
    end

    context 'when given nil' do
      let(:category) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the request to fetch groups fails' do
      before do
        stub_request(:get, "https://about.gitlab.com/groups.json").to_return(status: 404, body: '')
      end

      it 'raises an error' do
        expect { group }.to raise_error(described_class::Error)
      end
    end
  end

  describe '#pick_reviewer' do
    let(:group) { groups['tenant_scale'] }
    let(:identifiers) { %w[example identifier] }
    let(:available_reviewers) { %w[be1 be3 be5] }
    let(:expected_index) { Digest::SHA256.hexdigest(identifiers.join).to_i(16) % available_reviewers.size }

    before do
      allow(roulette).to receive(:reviewer_available?).and_return(false)

      available_reviewers.each do |reviewer|
        allow(roulette).to receive(:reviewer_available?).with(reviewer).and_return(true)
      end
    end

    subject(:pick_reviewer) { described_class.instance.pick_reviewer(group, identifiers) }

    it 'picks from available reviewers of default type' do
      expect(pick_reviewer).to eq(available_reviewers[expected_index])
    end

    context 'when no reviewers are available' do
      before do
        allow(roulette).to receive(:reviewer_available?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'when given nil' do
      let(:group) { nil }

      it { is_expected.to be_nil }
    end

    context 'with custom reviewer_types' do
      let(:available_reviewers) { %w[be1 fe1] }
      let(:expected_index) { Digest::SHA256.hexdigest(identifiers.join).to_i(16) % available_reviewers.size }

      subject(:pick_reviewer) do
        described_class.instance.pick_reviewer(group, identifiers,
          reviewer_types: %w[backend_engineers frontend_engineers])
      end

      it 'picks from the specified reviewer types' do
        expect(pick_reviewer).to eq(available_reviewers[expected_index])
      end
    end

    context 'with multiple reviewer_types containing duplicates' do
      let(:group) do
        {
          'backend_engineers' => %w[dev1 dev2],
          'fullstack_engineers' => %w[dev2 dev3]
        }
      end

      before do
        allow(roulette).to receive(:reviewer_available?).and_return(true)
      end

      subject(:pick_reviewer) do
        described_class.instance.pick_reviewer(group, identifiers,
          reviewer_types: %w[backend_engineers fullstack_engineers])
      end

      it 'deduplicates reviewers before selecting' do
        # dev2 appears in both backend and fullstack, but should only be counted once
        # so the pool is [dev1, dev2, dev3] (size 3), not [dev1, dev2, dev2, dev3] (size 4)
        expected_index = Digest::SHA256.hexdigest(identifiers.join).to_i(16) % 3
        expect(pick_reviewer).to eq(%w[dev1 dev2 dev3][expected_index])
      end
    end
  end

  describe '#pick_reviewer_for_feature_category' do
    let(:group) { groups['tenant_scale'] }
    let(:identifiers) { %w[example identifier] }
    let(:available_reviewers) { %w[be1 be3 be5] }
    let(:expected_index) { Digest::SHA256.hexdigest(identifiers.join).to_i(16) % available_reviewers.size }
    let(:category) { 'organization' }
    let(:fallback_feature_category) { nil }

    before do
      allow(roulette).to receive(:reviewer_available?).and_return(false)

      available_reviewers.each do |reviewer|
        allow(roulette).to receive(:reviewer_available?).with(reviewer).and_return(true)
      end
    end

    subject(:reviewer) do
      described_class.instance.pick_reviewer_for_feature_category(category, identifiers,
        fallback_feature_category: fallback_feature_category)
    end

    it 'finds a matching group and picks from available reviewers of default type' do
      expect(reviewer).to eq(available_reviewers[expected_index])
    end

    context 'when the matching group does not have available reviewers of default type' do
      let(:category) { 'category_b' }

      it { is_expected.to be_nil }

      context 'when a fallback_feature_category is passed' do
        let(:fallback_feature_category) { 'organization' }

        it 'returns a reviewer from that fallback_feature_category' do
          expect(reviewer).to eq(available_reviewers[expected_index])
        end
      end
    end

    context 'when only some reviewers are available via roulette' do
      before do
        allow(roulette).to receive(:reviewer_available?).and_return(false)
        allow(roulette).to receive(:reviewer_available?).with('be2').and_return(true)
      end

      it 'picks from reviewers marked as available' do
        expect(reviewer).to eq('be2')
      end
    end
  end

  describe '#labels_for_feature_category' do
    let(:category) { 'organization' }

    subject(:labels) { described_class.instance.labels_for_feature_category(category) }

    it 'returns the group label for the matching group' do
      expect(labels).to eq(['group::tenant scale'])
    end

    context 'when there is no matching group' do
      let(:category) { 'not_a_category' }

      it { is_expected.to eq([]) }
    end
  end

  describe '#available_reviewers_for_group' do
    let(:group) { groups['tenant_scale'] }

    before do
      allow(roulette).to receive(:reviewer_available?).and_return(false)
    end

    subject(:reviewers) do
      described_class.instance.available_reviewers_for_group(group, reviewer_types: reviewer_types)
    end

    context 'with default reviewer_types' do
      let(:available_reviewers) { %w[be1 be3 be5] }

      before do
        available_reviewers.each do |reviewer|
          allow(roulette).to receive(:reviewer_available?).with(reviewer).and_return(true)
        end
      end

      subject(:reviewers) { described_class.instance.available_reviewers_for_group(group) }

      it 'returns available reviewers of default type' do
        expect(reviewers).to eq(available_reviewers)
      end
    end

    context 'with a single reviewer type' do
      let(:reviewer_types) { ['backend_engineers'] }
      let(:available_reviewers) { %w[be1 be3] }

      before do
        available_reviewers.each do |reviewer|
          allow(roulette).to receive(:reviewer_available?).with(reviewer).and_return(true)
        end
      end

      it 'returns available reviewers of that type' do
        expect(reviewers).to eq(available_reviewers)
      end
    end

    context 'with multiple reviewer types' do
      let(:reviewer_types) { %w[backend_engineers frontend_engineers] }
      let(:available_reviewers) { %w[be1 fe1] }

      before do
        available_reviewers.each do |reviewer|
          allow(roulette).to receive(:reviewer_available?).with(reviewer).and_return(true)
        end
      end

      it 'returns available reviewers from all specified types' do
        expect(reviewers).to eq(available_reviewers)
      end
    end

    context 'with overlapping reviewer types' do
      let(:group) do
        {
          'backend_engineers' => %w[dev1 dev2],
          'fullstack_engineers' => %w[dev2 dev3]
        }
      end

      let(:reviewer_types) { %w[backend_engineers fullstack_engineers] }

      before do
        allow(roulette).to receive(:reviewer_available?).and_return(true)
      end

      it 'deduplicates reviewers' do
        expect(reviewers).to eq(%w[dev1 dev2 dev3])
      end
    end

    context 'when reviewer type does not exist in group' do
      let(:reviewer_types) { ['nonexistent_type'] }

      it 'returns empty array' do
        expect(reviewers).to eq([])
      end
    end

    context 'when group is nil' do
      let(:group) { nil }
      let(:reviewer_types) { ['engineers'] }

      it 'returns empty array' do
        expect(reviewers).to eq([])
      end
    end
  end
end
