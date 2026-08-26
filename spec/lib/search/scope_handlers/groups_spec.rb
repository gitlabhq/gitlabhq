# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ScopeHandlers::Groups, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public, name: 'test-parent') }
  let_it_be(:subgroup) { create(:group, :public, parent: group, name: 'test-child') }
  let_it_be(:nested_subgroup) { create(:group, :public, parent: subgroup, name: 'test-grandchild') }
  let_it_be(:other_group) { create(:group, :public, name: 'test-elsewhere') }

  let(:filters) { {} }
  let(:handler) { described_class.new(search_results) }

  describe '.scope_name' do
    it { expect(described_class.scope_name).to eq('groups') }
  end

  context 'for global search' do
    let(:search_results) { Gitlab::SearchResults.new(user, 'test', filters: filters) }

    it 'returns all matching groups the user can see' do
      expect(handler.objects).to match_array([group, subgroup, nested_subgroup, other_group])
    end

    it 'returns the number of matching groups' do
      expect(handler.formatted_count).to eq('4')
    end

    it 'excludes groups that do not match the query' do
      results = described_class.new(Gitlab::SearchResults.new(user, 'elsewhere', filters: filters)).objects

      expect(results).to contain_exactly(other_group)
    end
  end

  context 'for group search' do
    let(:search_results) { Gitlab::GroupSearchResults.new(user, 'test', group: group, filters: filters) }

    it 'returns descendants of the searched group and excludes the group itself' do
      expect(handler.objects).to match_array([subgroup, nested_subgroup])
    end

    it 'returns the number of matching descendants' do
      expect(handler.formatted_count).to eq('2')
    end
  end

  context 'with archived groups' do
    let_it_be(:archived_subgroup) { create(:group, :public, :archived, parent: group, name: 'test-archived') }

    let(:search_results) { Gitlab::GroupSearchResults.new(user, 'test', group: group, filters: filters) }

    it 'excludes archived groups by default' do
      expect(handler.objects).not_to include(archived_subgroup)
    end

    context 'when include_archived is set' do
      let(:filters) { { include_archived: true } }

      it 'includes archived groups' do
        expect(handler.objects).to include(archived_subgroup)
      end
    end
  end

  describe '#count' do
    let(:search_results) { Gitlab::SearchResults.new(user, 'test', filters: filters) }

    it 'is capped at the count limit' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:total_count).and_return(described_class::COUNT_LIMIT + 10)
      end

      expect(described_class.new(search_results).formatted_count).to eq(described_class::COUNT_LIMIT_MESSAGE)
    end
  end
end
