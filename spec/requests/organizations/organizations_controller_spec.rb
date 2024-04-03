# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization) }

  shared_examples 'when the user is signed in' do
    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      context 'as as admin', :enable_admin_mode do
        let_it_be(:user) { create(:admin) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end

      context 'as an organization user' do
        let_it_be(:user) { create :user }

        before do
          create :organization_user, organization: organization, user: user
        end

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  shared_examples 'controller action that requires authentication' do
    context 'when the user is not signed in' do
      it_behaves_like 'organization - redirects to sign in page'

      context 'when `ui_for_organizations` feature flag is disabled' do
        before do
          stub_feature_flags(ui_for_organizations: false)
        end

        it_behaves_like 'organization - redirects to sign in page'
      end
    end

    it_behaves_like 'when the user is signed in'
  end

  shared_examples 'controller action that requires authentication by an organization user' do
    it_behaves_like 'controller action that requires authentication'

    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'organization - not found response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  shared_examples 'controller action that requires authentication by any user' do
    it_behaves_like 'controller action that requires authentication'

    context 'when the user is signed in' do
      before do
        sign_in(user)
      end

      context 'with no association to an organization' do
        let_it_be(:user) { create(:user) }

        it_behaves_like 'organization - successful response'
        it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
      end
    end
  end

  shared_examples 'controller action that does not require authentication' do
    context 'when the user is not logged in' do
      it_behaves_like 'organization - not found response'
      it_behaves_like 'organization - action disabled by `ui_for_organizations` feature flag'
    end

    it_behaves_like 'when the user is signed in'
  end

  describe 'GET #show' do
    subject(:gitlab_request) { get organization_path(organization) }

    it_behaves_like 'controller action that does not require authentication'
  end

  describe 'GET #activity' do
    subject(:gitlab_request) { get activity_organization_path(organization) }

    it_behaves_like 'controller action that does not require authentication'

    context 'when requested in json format' do
      let_it_be(:user) { create(:organization_user, organization: organization).user }

      context 'without activities' do
        before do
          sign_in(user)
        end

        it 'renders empty array' do
          get activity_organization_path(organization, format: :json)

          expect(response.media_type).to eq('application/json')
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(0)
        end
      end

      context 'with activities' do
        let_it_be(:project) { create(:project, organization: organization) }

        before_all do
          project.add_developer(user)
          sign_in(user)
        end

        it 'loads events' do
          get activity_organization_path(organization, format: :json)

          expect(response.media_type).to eq('application/json')
          expect(json_response).to be_an(Array)
          expect(json_response.size).to eq(1)
        end
      end
    end
  end

  describe 'GET #groups_and_projects' do
    subject(:gitlab_request) { get groups_and_projects_organization_path(organization) }

    it_behaves_like 'controller action that does not require authentication'
  end

  describe 'GET #users' do
    subject(:gitlab_request) { get users_organization_path(organization) }

    it_behaves_like 'controller action that requires authentication by an organization user'
  end

  describe 'GET #new' do
    subject(:gitlab_request) { get new_organization_path }

    it_behaves_like 'controller action that requires authentication by any user'

    context 'when user is signed in and `allow_organization_creation` feature flag is disabled' do
      let_it_be(:user) { create(:user) }

      before do
        stub_feature_flags(allow_organization_creation: false)
        sign_in(user)
      end

      it_behaves_like 'organization - not found response'
    end
  end

  describe 'GET #index' do
    subject(:gitlab_request) { get organizations_path }

    it_behaves_like 'controller action that requires authentication by any user'
  end

  describe 'POST #preview_markdown' do
    subject(:gitlab_request) { post preview_markdown_organizations_path, params: { text: '### Foo \n **bar**' } }

    it_behaves_like 'controller action that requires authentication by any user'

    context 'when the user is signed in' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      it 'returns html from markdown' do
        stub_commonmark_sourcepos_disabled
        sign_in(user)
        gitlab_request

        body = Gitlab::Json.parse(response.body)['body']

        expect(body).not_to include('Foo</h3>')
        expect(body).to include('<strong>bar</strong>')
      end
    end
  end
end
