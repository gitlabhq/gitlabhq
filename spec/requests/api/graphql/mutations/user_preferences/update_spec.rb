# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::UserPreferences::Update, feature_category: :user_profile do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:sort_value) { 'TITLE_ASC' }

  let(:input) do
    {
      'issuesSort' => sort_value
    }
  end

  let(:mutation) { graphql_mutation(:userPreferencesUpdate, input) }
  let(:mutation_response) { graphql_mutation_response(:userPreferencesUpdate) }

  context 'when user has no existing preference' do
    it 'creates the user preference record' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)

      expect(current_user.user_preference.persisted?).to eq(true)
      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
    end
  end

  context 'when user has existing preference' do
    before do
      current_user.create_user_preference!(issues_sort: Types::IssueSortEnum.values['TITLE_DESC'].value)
    end

    it 'updates the existing value' do
      post_graphql_mutation(mutation, current_user: current_user)

      current_user.user_preference.reload

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['userPreferences']['issuesSort']).to eq(sort_value)

      expect(current_user.user_preference.issues_sort).to eq(Types::IssueSortEnum.values[sort_value].value.to_s)
    end
  end
end
