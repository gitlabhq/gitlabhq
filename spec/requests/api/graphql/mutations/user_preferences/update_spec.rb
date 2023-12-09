# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::UserPreferences::Update, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:sort_value) { 'TITLE_ASC' }

  let(:input) do
    {
      'issuesSort' => sort_value,
      'visibilityPipelineIdType' => 'IID',
      'useWebIdeExtensionMarketplace' => true
    }
  end

  let(:mutation) { graphql_mutation(:userPreferencesUpdate, input) }
  let(:mutation_response) { graphql_mutation_response(:userPreferencesUpdate) }

  context 'when user has no existing preference' do
    it 'creates the user preference record' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)
      expect(mutation_response['userPreferences']['visibilityPipelineIdType']).to eq('IID')
      expect(mutation_response['userPreferences']['useWebIdeExtensionMarketplace']).to eq(true)

      expect(current_user.user_preference.persisted?).to eq(true)
      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
      expect(current_user.user_preference.use_web_ide_extension_marketplace).to eq(true)
    end
  end

  context 'when user has existing preference' do
    let(:init_user_preference) do
      {
        issues_sort: Types::IssueSortEnum.values['TITLE_DESC'].value,
        visibility_pipeline_id_type: 'id',
        use_web_ide_extension_marketplace: true
      }
    end

    before do
      current_user.create_user_preference!(init_user_preference)
    end

    it 'updates the existing value' do
      post_graphql_mutation(mutation, current_user: current_user)

      current_user.user_preference.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)
      expect(mutation_response['userPreferences']['visibilityPipelineIdType']).to eq('IID')

      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
      expect(current_user.user_preference.visibility_pipeline_id_type).to eq('iid')
    end

    context 'when input has nil attributes' do
      let(:input) do
        {
          'issuesSort' => nil,
          'visibilityPipelineIdType' => nil,
          'useWebIdeExtensionMarketplace' => nil
        }
      end

      it 'updates only nullable attributes' do
        post_graphql_mutation(mutation, current_user: current_user)

        current_user.user_preference.reload

        expect(current_user.user_preference).to have_attributes({
          # These are nullable and are exepcted to change
          issues_sort: nil,
          # These should not have changed
          visibility_pipeline_id_type: init_user_preference[:visibility_pipeline_id_type],
          use_web_ide_extension_marketplace: init_user_preference[:use_web_ide_extension_marketplace]
        })
      end
    end
  end
end
