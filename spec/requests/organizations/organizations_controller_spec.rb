# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationsController, feature_category: :cell do
  let_it_be(:organization) { create(:organization, :private) }

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

      context 'as an organization owner' do
        let_it_be(:user) { create :user }

        before do
          create :organization_owner, organization: organization, user: user
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

        it 'returns empty array and no next page' do
          get activity_organization_path(organization, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(0)
          expect(json_response['has_next_page']).to eq(false)
        end
      end

      context 'with less activities than limit' do
        let_it_be(:project) { create(:project, organization: organization) }

        before_all do
          project.add_developer(user)
          sign_in(user)
        end

        it 'returns events and no next page' do
          get activity_organization_path(organization, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(1)
          expect(json_response['has_next_page']).to eq(false)
        end
      end

      context 'with more activities than passed in limit' do
        let_it_be(:project) { create(:project, organization: organization) }
        let_it_be(:events) { create_list(:event, 3, project: project) }

        before_all do
          project.add_developer(user)
          sign_in(user)
        end

        it 'returns events and next page' do
          get activity_organization_path(organization, limit: 2, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(2)
          expect(json_response['has_next_page']).to eq(true)
        end
      end

      context 'with passed in limit greater than allowed' do
        let_it_be(:mock_max_event_limit) { 3 }
        let_it_be(:project) { create(:project, organization: organization) }
        let_it_be(:events) { create_list(:event, mock_max_event_limit + 1, project: project) }

        before_all do
          project.add_developer(user)
          sign_in(user)
        end

        before do
          stub_const("#{described_class}::DEFAULT_ACTIVITY_EVENT_LIMIT", mock_max_event_limit)
        end

        it 'returns max events and next page boolean' do
          get activity_organization_path(organization, limit: 19, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(mock_max_event_limit)
          expect(json_response['has_next_page']).to eq(true)
        end
      end

      context 'when most recent activities are from projects inaccessible to user' do
        let_it_be(:limit) { 5 }

        let_it_be(:project) { create(:project, organization: organization) }
        let_it_be(:events) { create_list(:event, limit, project: project) }

        let_it_be(:private_projects) { create(:project, :private, organization: organization) }
        let_it_be(:private_events) { create_list(:event, limit, project: private_projects) }

        before_all do
          project.add_developer(user)
          sign_in(user)
        end

        it 'returns events from projects where user has access to' do
          get activity_organization_path(organization, limit: 5, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(limit)
        end
      end

      context 'when most recent activities are from groups inaccessible to user' do
        let_it_be(:limit) { 5 }

        let_it_be(:group) { create(:group, :private, organization: organization) }
        let_it_be(:events) do
          create_list(:event, limit, :created, target: create(:milestone, group: group), group: group)
        end

        let_it_be(:private_group) { create(:group, :private, organization: organization) }
        let_it_be(:private_events) do
          create_list(
            :event,
            limit,
            :created,
            group: private_group,
            target: create(:milestone, group: private_group)
          )
        end

        before_all do
          group.add_developer(user)
          sign_in(user)
        end

        it 'returns events from groups where user has access to' do
          get activity_organization_path(organization, limit: 5, format: :json)

          expect(response.media_type).to eq('application/json')

          expect(json_response['events']).to be_an(Array)
          expect(json_response['events'].size).to eq(limit)
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
