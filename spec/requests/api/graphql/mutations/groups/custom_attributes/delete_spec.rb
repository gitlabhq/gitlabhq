# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DeleteGroupCustomAttribute', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  let(:key) { 'department' }

  let(:mutation) do
    graphql_mutation(
      :delete_group_custom_attribute,
      {
        group_path: group.full_path,
        key: key
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

  let(:mutation_response) { graphql_mutation_response(:delete_group_custom_attribute) }

  context 'when user is not an admin' do
    let(:current_user) { user }

    before_all do
      group.add_owner(user)
      create(:group_custom_attribute, group: group, key: 'department', value: 'engineering')
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not delete the custom attribute' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { GroupCustomAttribute.count }
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when custom attribute exists' do
      let!(:custom_attribute) do
        create(:group_custom_attribute, group: group, key: 'department', value: 'engineering')
      end

      it 'deletes the custom attribute' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { group.custom_attributes.count }.by(-1)

        expect(mutation_response['customAttribute']).to eq({
          'key' => 'department',
          'value' => 'engineering'
        })
        expect(mutation_response['errors']).to eq([])
      end

      it 'returns the deleted attribute data' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['customAttribute']['key']).to eq('department')
        expect(mutation_response['customAttribute']['value']).to eq('engineering')
      end
    end

    context 'when custom attribute does not exist' do
      let(:key) { 'nonexistent' }

      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['customAttribute']).to be_nil
        expect(mutation_response['errors']).to contain_exactly('Custom attribute not found')
      end

      it 'does not change the count' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { GroupCustomAttribute.count }
      end
    end

    context 'when group does not exist' do
      let(:mutation) do
        graphql_mutation(
          :delete_group_custom_attribute,
          {
            group_path: 'nonexistent/group',
            key: key
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

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when deleting one of multiple attributes' do
      before do
        create(:group_custom_attribute, group: group, key: 'department', value: 'engineering')
        create(:group_custom_attribute, group: group, key: 'priority', value: 'high')
      end

      it 'only deletes the specified attribute' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { group.custom_attributes.count }.by(-1)

        expect(group.custom_attributes.pluck(:key)).to contain_exactly('priority')
      end
    end

    context 'with nested group' do
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:child_group) { create(:group, parent: parent_group) }

      let!(:child_attribute) do
        create(:group_custom_attribute, group: child_group, key: 'team', value: 'backend')
      end

      let(:mutation) do
        graphql_mutation(
          :delete_group_custom_attribute,
          {
            group_path: child_group.full_path,
            key: 'team'
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

      it 'deletes custom attribute from nested group' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { child_group.custom_attributes.count }.by(-1)

        expect(mutation_response['customAttribute']).to eq({
          'key' => 'team',
          'value' => 'backend'
        })
      end
    end
  end
end
