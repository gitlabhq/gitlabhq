# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user_settings/personal_access_tokens/legacy_new.html.haml', feature_category: :system_access do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need these objects to be persisted
  let_it_be(:user) { create(:user) }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  before do
    sign_in(user)
  end

  context 'when VSCode extension parameters are provided' do
    let(:access_token_params) do
      {
        name: 'GitLab Workflow Extension',
        description: 'Token for VSCode extension',
        scopes: [:api, :read_user]
      }
    end

    before do
      assign(:access_token_params, access_token_params)
    end

    it 'shows the legacy personal access token form with pre-filled data' do
      render

      expect(rendered).to have_selector('div#js-create-legacy-token-app') do |element|
        expect(element['data-access-token-name']).to eq('GitLab Workflow Extension')
        expect(element['data-access-token-description']).to eq('Token for VSCode extension')
        expect(element['data-access-token-scopes']).to eq(%w[api read_user].to_json)
      end
    end
  end

  context 'when no access token parameters are provided' do
    before do
      assign(:access_token_params, {})
    end

    it 'shows the legacy personal access token form without pre-filled data' do
      render

      expect(rendered).to have_selector('div#js-create-legacy-token-app')
    end
  end
end
