# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SetGroupCustomAttribute', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:key) { 'department' }
  let(:value) { 'engineering' }

  let(:mutation) do
    graphql_mutation(
      :set_group_custom_attribute,
      {
        group_path: group.full_path,
        key: key,
        value: value
      },
      <<~FIELDS
        customAttribute {
          key
          value
        }
        errors
      FIELDS
    )
  end

  let(:mutation_response) { graphql_mutation_response(:set_group_custom_attribute) }

  context 'when user is not an admin' do
    let(:current_user) { user }

    before_all do
      group.add_owner(user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create a custom attribute' do
      expect { post_graphql_mutation(mutation, current_user: user) }
        .not_to change { GroupCustomAttribute.count }
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    context 'when creating a new custom attribute' do
      it 'creates the custom attribute' do
        expect { post_graphql_mutation(mutation, current_user: admin) }
          .to change { group.custom_attributes.count }.by(1)

        expect(mutation_response['customAttribute']).to eq({
          'key' => key,
          'value' => value
        })
        expect(mutation_response['errors']).to eq([])
      end
    end

    context 'when updating an existing custom attribute' do
      before do
        group.custom_attributes.create!(key: 'department', value: 'old_value')
      end

      it 'updates the existing custom attribute' do
        expect { post_graphql_mutation(mutation, current_user: admin) }
          .not_to change { group.custom_attributes.count }

        expect(mutation_response['customAttribute']['value']).to eq(value)
      end
    end

    context 'when updating one of multiple attributes' do
      before do
        group.custom_attributes.create!(key: 'department', value: 'old_value')
        group.custom_attributes.create!(key: 'priority', value: 'high')
      end

      it 'only updates the specified attribute' do
        expect { post_graphql_mutation(mutation, current_user: admin) }
          .not_to change { group.custom_attributes.count }

        expect(group.custom_attributes.pluck(:key, :value)).to contain_exactly(
          ['department', value],
          %w[priority high]
        )
      end
    end

    context 'when group does not exist' do
      let(:mutation) do
        graphql_mutation(
          :set_group_custom_attribute,
          {
            group_path: 'nonexistent/group',
            key: key,
            value: value
          },
          <<~FIELDS
            customAttribute {
              key
              value
            }
            errors
          FIELDS
        )
      end

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: admin)

        expect(graphql_errors).to be_present
      end
    end

    context 'with nested group' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:child_group) { create(:group, parent: parent_group) }

      let(:mutation) do
        graphql_mutation(
          :set_group_custom_attribute,
          {
            group_path: child_group.full_path,
            key: key,
            value: value
          },
          <<~FIELDS
            customAttribute {
              key
              value
            }
            errors
          FIELDS
        )
      end

      it 'creates custom attribute on nested group' do
        expect { post_graphql_mutation(mutation, current_user: admin) }
          .to change { child_group.custom_attributes.count }.by(1)

        expect(mutation_response['customAttribute']).to eq({
          'key' => key,
          'value' => value
        })
      end
    end
  end
end
