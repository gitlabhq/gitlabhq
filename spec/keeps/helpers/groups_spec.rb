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
        'backend_engineers' => %w[be1 be2 be3 be4 be5],
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
        'backend_engineers' => %w[],
        'triage_ops_config' => nil
      }
    }
  end

  before do
    allow(Keeps::Helpers::ReviewerRoulette).to receive(:new).and_return(roulette)
    stub_request(:get, "https://about.gitlab.com/groups.json").to_return(status: 200, body: groups.to_json)
  end

  describe '#group_for_feature_category' do
    let(:category) { 'organization' }

    subject(:group) { described_class.new.group_for_feature_category(category) }

    it { is_expected.to eq(groups['tenant_scale']) }

    context 'when the category does not exist' do
      let(:category) { 'missing-category' }

      it { is_expected.to eq(nil) }
    end

    context 'when given nil' do
      let(:category) { nil }

      it { is_expected.to eq(nil) }
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

    subject(:pick_reviewer) { described_class.new.pick_reviewer(group, identifiers) }

    it 'picks from available reviewers only' do
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
      described_class.new.pick_reviewer_for_feature_category(category, identifiers,
        fallback_feature_category: fallback_feature_category)
    end

    it 'finds a matching group and picks a reviewer from available engineers only' do
      expect(reviewer).to eq(available_reviewers[expected_index])
    end

    context 'when the matching group does not have available backend_engineers' do
      let(:category) { 'category_b' }

      it { is_expected.to be_nil }

      context 'when a fallback_feature_category is passed' do
        let(:fallback_feature_category) { 'organization' }

        it 'returns a reviewer from that fallback_feature_category' do
          expect(reviewer).to eq(available_reviewers[expected_index])
        end
      end
    end

    context 'when no reviewers are available in the primary category' do
      let(:fallback_feature_category) { 'organization' }

      before do
        allow(roulette).to receive(:reviewer_available?).and_return(false)
        allow(roulette).to receive(:reviewer_available?).with('be2').and_return(true)
      end

      it 'falls back to the fallback category' do
        expect(reviewer).to eq('be2')
      end
    end
  end

  describe '#labels_for_feature_category' do
    let(:category) { 'organization' }

    subject(:labels) { described_class.new.labels_for_feature_category(category) }

    it 'returns the group label for the matching group' do
      expect(labels).to eq(['group::tenant scale'])
    end

    context 'when there is no matching group' do
      let(:category) { 'not_a_category' }

      it { is_expected.to eq([]) }
    end
  end
end
