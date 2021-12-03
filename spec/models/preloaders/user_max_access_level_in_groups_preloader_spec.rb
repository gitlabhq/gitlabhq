# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::UserMaxAccessLevelInGroupsPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:group1) { create(:group, :private).tap { |g| g.add_developer(user) } }
  let_it_be(:group2) { create(:group, :private).tap { |g| g.add_developer(user) } }
  let_it_be(:group3) { create(:group, :private) }

  let(:max_query_regex) { /SELECT MAX\("members"\."access_level"\).+/ }
  let(:groups) { [group1, group2, group3] }

  shared_examples 'executes N max member permission queries to the DB' do
    it 'executes the specified max membership queries' do
      expect { groups.each { |group| user.can?(:read_group, group) } }
        .to make_queries_matching(max_query_regex, expected_query_count)
    end
  end

  context 'when the preloader is used', :request_store do
    before do
      described_class.new(groups, user).execute
    end

    it_behaves_like 'executes N max member permission queries to the DB' do
      # Will query all groups where the user is not already a member
      let(:expected_query_count) { 1 }
    end

    context 'when user has access but is not a direct member of the group' do
      let(:groups) { [group1, group2, group3, create(:group, :private, parent: group1)] }

      it_behaves_like 'executes N max member permission queries to the DB' do
        # One query for group with no access and another one where the user is not a direct member
        let(:expected_query_count) { 2 }
      end
    end
  end

  context 'when the preloader is not used', :request_store do
    it_behaves_like 'executes N max member permission queries to the DB' do
      let(:expected_query_count) { groups.count }
    end
  end
end
