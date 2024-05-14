# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMaxAccessLevelInGroupsPreloader, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:group1) { create(:group, :private, developers: user) }
  let_it_be(:group2) { create(:group, :private, developers: user) }
  let_it_be(:group3) { create(:group, :private) }

  let(:max_query_regex) { /SELECT MAX\("members"\."access_level"\).+/ }
  let(:groups) { [group1, group2, group3] }

  shared_examples 'executes N max member permission queries to the DB' do
    it 'executes the specified max membership queries' do
      expect { groups.each { |group| user.can?(:read_group, group) } }
        .to make_queries_matching(max_query_regex, expected_query_count)
    end

    it 'caches the correct access_level for each group' do
      groups.each do |group|
        access_level_from_db = group.members_with_parents.where(user_id: user.id).group(:user_id).maximum(:access_level)[user.id] || Gitlab::Access::NO_ACCESS
        cached_access_level = group.max_member_access_for_user(user)

        expect(cached_access_level).to eq(access_level_from_db)
      end
    end
  end

  context 'when the preloader is used', :request_store do
    context 'when user has indirect access to groups' do
      let_it_be(:child_maintainer) { create(:group, :private, parent: group1, maintainers: user) }
      let_it_be(:child_indirect_access) { create(:group, :private, parent: group1) }

      let(:groups) { [group1, group2, group3, child_maintainer, child_indirect_access] }

      it_behaves_like 'executes N max member permission queries to the DB' do
        before do
          described_class.new(groups, user).execute
        end

        let(:expected_query_count) { 0 }
      end

      context 'for groups arising from group shares' do
        let_it_be(:group4) { create(:group, :private) }
        let_it_be(:group4_subgroup) { create(:group, :private, parent: group4) }

        let(:groups) { [group4, group4_subgroup] }

        before do
          create(:group_group_link, :guest, shared_with_group: group1, shared_group: group4)
        end

        it 'sets the right access level in cache for groups arising from group shares' do
          described_class.new(groups, user).execute

          groups.each do |group|
            cached_access_level = group.max_member_access_for_user(user)

            expect(cached_access_level).to eq(Gitlab::Access::GUEST)
          end
        end
      end
    end
  end

  context 'when the preloader is not used', :request_store do
    it_behaves_like 'executes N max member permission queries to the DB' do
      let(:expected_query_count) { groups.count }
    end
  end
end
