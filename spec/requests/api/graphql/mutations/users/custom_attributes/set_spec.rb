# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'UserCustomAttributeSet', feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:target_user) { create(:user) }

  let(:key) { 'department' }
  let(:value) { 'engineering' }

  let(:mutation) do
    graphql_mutation(
      :user_custom_attribute_set,
      {
        user_id: target_user.to_global_id.to_s,
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

  let(:mutation_response) { graphql_mutation_response(:user_custom_attribute_set) }

  subject(:post_mutation) { post_graphql_mutation(mutation, current_user: current_user) }

  context 'when user is not an admin' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create a custom attribute' do
      expect { post_mutation }.not_to change { UserCustomAttribute.count }
    end
  end

  context 'when user is an admin', :enable_admin_mode do
    let_it_be(:admin) { create(:admin) }

    let(:current_user) { admin }

    context 'when creating a new custom attribute' do
      it 'creates the custom attribute' do
        expect { post_mutation }.to change { target_user.custom_attributes.count }.by(1)

        expect(mutation_response).to include(
          'customAttribute' => {
            'key' => key,
            'value' => value
          },
          'errors' => []
        )
      end
    end

    context 'when updating an existing custom attribute' do
      before do
        target_user.custom_attributes.create!(key: 'department', value: 'old_value')
      end

      it 'updates the existing custom attribute' do
        expect { post_mutation }.not_to change { target_user.custom_attributes.count }

        expect(mutation_response['customAttribute']['value']).to eq(value)
      end
    end

    context 'when user does not exist' do
      let(:mutation) do
        graphql_mutation(
          :user_custom_attribute_set,
          {
            user_id: "gid://gitlab/User/0",
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

    context 'when validation fails' do
      using RSpec::Parameterized::TableSyntax

      where(:key, :value, :expected_error) do
        ''           | 'enginering' | "Key can't be blank"
        'department' | ''           | "Value can't be blank"
      end

      with_them do
        it 'does not create a custom attribute and returns validation errors' do
          expect { post_mutation }.not_to change { UserCustomAttribute.count }

          expect(mutation_response).to include(
            'customAttribute' => nil,
            'errors' => [expected_error]
          )
        end
      end
    end
  end
end
