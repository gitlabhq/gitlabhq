# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups', :with_license, feature_category: :subgroups do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:private_group) { create(:group, :private) }

  let(:fields) do
    <<~FIELDS
      nodes {
        #{all_graphql_fields_for('Group')}
      }
    FIELDS
  end

  let(:query) do
    <<~QUERY
      query {
        groups {
          #{fields}
        }
      }
    QUERY
  end

  subject { post_graphql(query, current_user: user) }

  describe "Query groups(search)" do
    let(:groups) { graphql_data_at(:groups, :nodes) }
    let(:names) { groups.map { |group| group["name"] } } # rubocop: disable Rails/Pluck

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end
    end

    it 'includes public groups' do
      subject

      expect(names).to eq([public_group.name])
    end

    it 'includes accessible private groups ordered by name' do
      private_group.add_maintainer(user)

      subject

      expect(names).to eq([public_group.name, private_group.name])
    end

    context 'with `search` argument' do
      let_it_be(:other_group) { create(:group, name: 'other-group') }

      let(:query) do
        <<~QUERY
          query {
            groups(search: "oth") {
              #{fields}
            }
          }
        QUERY
      end

      it 'filters groups by name' do
        subject

        expect(names).to contain_exactly(other_group.name)
      end
    end
  end
end
