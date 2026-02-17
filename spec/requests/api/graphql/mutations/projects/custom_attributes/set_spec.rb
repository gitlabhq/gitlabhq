# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProjectCustomAttributeSet', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:key) { 'department' }
  let(:value) { 'engineering' }

  let(:mutation) do
    graphql_mutation(
      :project_custom_attribute_set,
      {
        project_path: project.full_path,
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

  let(:mutation_response) { graphql_mutation_response(:project_custom_attribute_set) }

  context 'when user is not an admin' do
    let(:current_user) { user }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create a custom attribute' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { ProjectCustomAttribute.count }
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when creating a new custom attribute' do
      it 'creates the custom attribute' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { project.custom_attributes.count }.by(1)

        expect(mutation_response['customAttribute']).to eq({
          'key' => key,
          'value' => value
        })
        expect(mutation_response['errors']).to eq([])
      end
    end

    context 'when updating an existing custom attribute' do
      let_it_be(:existing_attribute) do
        create(:project_custom_attribute, project: project, key: 'department', value: 'old_value')
      end

      it 'updates the existing custom attribute' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { project.custom_attributes.count }

        expect(mutation_response['customAttribute']).to eq({
          'key' => key,
          'value' => value
        })
        expect(mutation_response['errors']).to eq([])

        expect(existing_attribute.reload.value).to eq(value)
      end
    end

    context 'when project does not exist' do
      let(:mutation) do
        graphql_mutation(
          :project_custom_attribute_set,
          {
            project_path: 'nonexistent/project',
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

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when key is empty' do
      let(:key) { '' }

      it 'returns validation errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['customAttribute']).to be_nil
        expect(mutation_response['errors']).to include("Key can't be blank")
      end
    end

    context 'when value is empty' do
      let(:value) { '' }

      it 'returns validation errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['customAttribute']).to be_nil
        expect(mutation_response['errors']).to include("Value can't be blank")
      end
    end
  end
end
