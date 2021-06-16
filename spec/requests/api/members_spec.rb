# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Members do
  let(:maintainer) { create(:user, username: 'maintainer_user') }
  let(:developer) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:stranger) { create(:user) }
  let(:user_with_minimal_access) { create(:user) }

  let(:project) do
    create(:project, :public, creator_id: maintainer.id, namespace: maintainer.namespace) do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.request_access(access_requester)
    end
  end

  let!(:group) do
    create(:group, :public) do |group|
      group.add_developer(developer)
      group.add_owner(maintainer)
      create(:group_member, :minimal_access, source: group, user: user_with_minimal_access)
      group.request_access(access_requester)
    end
  end

  shared_examples 'GET /:source_type/:id/members/(all)' do |source_type, all|
    let(:members_url) do
      (+"/#{source_type.pluralize}/#{source.id}/members").tap do |url|
        url << "/all" if all
      end
    end

    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api(members_url, stranger) }
      end

      %i[maintainer developer access_requester stranger].each do |type|
        context "when authenticated as a #{type}" do
          it 'returns 200' do
            user = public_send(type)

            get api(members_url, user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(2)
            expect(json_response.map { |u| u['id'] }).to match_array [maintainer.id, developer.id]
          end
        end
      end

      it 'avoids N+1 queries' do
        # Establish baseline
        get api(members_url, maintainer)

        control = ActiveRecord::QueryRecorder.new do
          get api(members_url, maintainer)
        end

        project.add_developer(create(:user))

        expect do
          get api(members_url, maintainer)
        end.not_to exceed_query_limit(control)
      end

      it 'does not return invitees' do
        create(:"#{source_type}_member", invite_token: '123', invite_email: 'test@abc.com', source: source, user: nil)

        get api(members_url, developer)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.size).to eq(2)
        expect(json_response.map { |u| u['id'] }).to match_array [maintainer.id, developer.id]
      end

      it 'finds members with query string' do
        get api(members_url, developer), params: { query: maintainer.username }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(1)
        expect(json_response.first['username']).to eq(maintainer.username)
      end

      it 'finds members with the given user_ids' do
        get api(members_url, developer), params: { user_ids: [maintainer.id, developer.id, stranger.id] }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.map { |u| u['id'] }).to contain_exactly(maintainer.id, developer.id)
      end

      it 'finds all members with no query specified' do
        get api(members_url, developer), params: { query: '' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(2)
        expect(json_response.map { |u| u['id'] }).to match_array [maintainer.id, developer.id]
      end
    end
  end

  describe 'GET /:source_type/:id/members/all' do
    let(:nested_user) { create(:user) }
    let(:project_user) { create(:user) }
    let(:linked_group_user) { create(:user) }
    let!(:project_group_link) { create(:project_group_link, project: project, group: linked_group) }

    let(:project) do
      create(:project, :public, group: nested_group) do |project|
        project.add_developer(project_user)
      end
    end

    let(:linked_group) do
      create(:group) do |linked_group|
        linked_group.add_developer(linked_group_user)
      end
    end

    let(:nested_group) do
      create(:group, parent: group) do |nested_group|
        nested_group.add_developer(nested_user)
      end
    end

    it 'finds all project members including inherited members' do
      get api("/projects/#{project.id}/members/all", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |u| u['id'] }).to match_array [maintainer.id, developer.id, nested_user.id, project_user.id, linked_group_user.id]
    end

    it 'returns only one member for each user without returning duplicated members' do
      linked_group.add_developer(developer)

      get api("/projects/#{project.id}/members/all", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array

      expected_users_and_access_levels = [
        [developer.id, Gitlab::Access::DEVELOPER],
        [maintainer.id, Gitlab::Access::OWNER],
        [nested_user.id, Gitlab::Access::DEVELOPER],
        [project_user.id, Gitlab::Access::DEVELOPER],
        [linked_group_user.id, Gitlab::Access::DEVELOPER]
      ]
      expect(json_response.map { |u| [u['id'], u['access_level']] }).to match_array(expected_users_and_access_levels)
    end

    it 'finds all group members including inherited members' do
      get api("/groups/#{nested_group.id}/members/all", developer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to include_pagination_headers
      expect(json_response).to be_an Array
      expect(json_response.map { |u| u['id'] }).to match_array [maintainer.id, developer.id, nested_user.id]
    end
  end

  shared_examples 'GET /:source_type/:id/members/(all/):user_id' do |source_type, all|
    context "with :source_type == #{source_type.pluralize} and all == #{all}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/members/#{all ? 'all/' : ''}#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 200' do
              user = public_send(type)
              get api("/#{source_type.pluralize}/#{source.id}/members/#{all ? 'all/' : ''}#{developer.id}", user)

              expect(response).to have_gitlab_http_status(:ok)
              # User attributes
              expect(json_response['id']).to eq(developer.id)
              expect(json_response['name']).to eq(developer.name)
              expect(json_response['username']).to eq(developer.username)
              expect(json_response['state']).to eq(developer.state)
              expect(json_response['avatar_url']).to eq(developer.avatar_url)
              expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(developer))

              # Member attributes
              expect(json_response['access_level']).to eq(Member::DEVELOPER)
              expect(json_response['created_at'].to_time).to be_like_time(developer.created_at)
            end
          end
        end
      end
    end
  end

  shared_examples 'POST /:source_type/:id/members' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post api("/#{source_type.pluralize}/#{source.id}/members", stranger),
               params: { user_id: access_requester.id, access_level: Member::MAINTAINER }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              post api("/#{source_type.pluralize}/#{source.id}/members", user),
                   params: { user_id: access_requester.id, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        context 'and new member is already a requester' do
          it 'transforms the requester into a proper member' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                   params: { user_id: access_requester.id, access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:created)
            end.to change { source.members.count }.by(1)
            expect(source.requesters.count).to eq(0)
            expect(json_response['id']).to eq(access_requester.id)
            expect(json_response['access_level']).to eq(Member::MAINTAINER)
          end
        end

        it 'creates a new member' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                 params: { user_id: stranger.id, access_level: Member::DEVELOPER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.count }.by(1)
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['access_level']).to eq(Member::DEVELOPER)
        end

        context 'with invite_source considerations', :snowplow do
          let(:params) { { user_id: stranger.id, access_level: Member::DEVELOPER } }

          it 'tracks the invite source as api' do
            post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                 params: params

            expect_snowplow_event(
              category: 'Members::CreateService',
              action: 'create_member',
              label: 'members-api',
              property: 'existing_user',
              user: maintainer
            )
          end

          it 'tracks the invite source from params' do
            post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                 params: params.merge(invite_source: '_invite_source_')

            expect_snowplow_event(
              category: 'Members::CreateService',
              action: 'create_member',
              label: '_invite_source_',
              property: 'existing_user',
              user: maintainer
            )
          end
        end

        context 'when executing the Members::CreateService for multiple user_ids' do
          let(:user_ids) { [stranger.id, access_requester.id].join(',') }

          it 'returns success when it successfully create all members' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                   params: { user_id: user_ids, access_level: Member::DEVELOPER }

              expect(response).to have_gitlab_http_status(:created)
            end.to change { source.members.count }.by(2)
            expect(json_response['status']).to eq('success')
          end

          it 'returns the error message if there was an error adding members to group' do
            error_message = 'Unable to find User ID'
            allow_next_instance_of(::Members::CreateService) do |service|
              expect(service).to receive(:execute).and_return({ status: :error, message: error_message })
            end

            expect do
              post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                   params: { user_id: user_ids, access_level: Member::DEVELOPER }
            end.not_to change { source.members.count }
            expect(json_response['status']).to eq('error')
            expect(json_response['message']).to eq(error_message)
          end

          context 'with invite_source considerations', :snowplow do
            let(:params) { { user_id: user_ids, access_level: Member::DEVELOPER } }

            it 'tracks the invite source as api' do
              post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                   params: params

              expect_snowplow_event(
                category: 'Members::CreateService',
                action: 'create_member',
                label: 'members-api',
                property: 'existing_user',
                user: maintainer
              )
            end

            it 'tracks the invite source from params' do
              post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
                   params: params.merge(invite_source: '_invite_source_')

              expect_snowplow_event(
                category: 'Members::CreateService',
                action: 'create_member',
                label: '_invite_source_',
                property: 'existing_user',
                user: maintainer
              )
            end
          end
        end
      end

      context 'access levels' do
        it 'does not create the member if group level is higher' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
               params: { user_id: stranger.id, access_level: Member::REPORTER }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['access_level']).to eq(["should be greater than or equal to Developer inherited membership from group #{parent.name}"])
        end

        it 'creates the member if group level is lower' do
          parent = create(:group)

          group.update!(parent: parent)
          project.update!(group: group)
          parent.add_developer(stranger)

          post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
               params: { user_id: stranger.id, access_level: Member::MAINTAINER }

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['access_level']).to eq(Member::MAINTAINER)
        end
      end

      context 'access expiry date' do
        subject do
          post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
               params: { user_id: stranger.id, access_level: Member::DEVELOPER, expires_at: expires_at }
        end

        context 'when set to a date in the past' do
          let(:expires_at) { 2.days.ago.to_date }

          it 'does not create a member' do
            expect do
              subject
            end.not_to change { source.members.count }

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'expires_at' => ['cannot be a date in the past'] })
          end
        end

        context 'when set to a date in the future' do
          let(:expires_at) { 2.days.from_now.to_date }

          it 'creates a member' do
            expect do
              subject
            end.to change { source.members.count }.by(1)

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['id']).to eq(stranger.id)
            expect(json_response['expires_at']).to eq(expires_at.to_s)
          end
        end
      end

      it "returns 409 if member already exists" do
        post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
             params: { user_id: maintainer.id, access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:conflict)
      end

      it 'returns 404 when the user_id is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
             params: { user_id: 0, access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to eq('404 User Not Found')
      end

      it 'returns 400 when user_id is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
             params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 when access_level is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
             params: { user_id: stranger.id }

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 when access_level is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
             params: { user_id: stranger.id, access_level: non_existing_record_access_level }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'adding project bot' do
      let_it_be(:project_bot) { create(:user, :project_bot) }

      before do
        unrelated_project = create(:project)
        unrelated_project.add_maintainer(project_bot)
      end

      it 'returns 400' do
        expect do
          post api("/#{source_type.pluralize}/#{source.id}/members", maintainer),
               params: { user_id: project_bot.id, access_level: Member::DEVELOPER }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['user_id']).to(
            include('project bots cannot be added to other groups / projects'))
        end.not_to change { project.members.count }
      end
    end
  end

  shared_examples 'PUT /:source_type/:id/members/:user_id' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger),
              params: { access_level: Member::MAINTAINER }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user),
                  params: { access_level: Member::MAINTAINER }

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'updates the member' do
          put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer),
              params: { access_level: Member::MAINTAINER }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(developer.id)
          expect(json_response['access_level']).to eq(Member::MAINTAINER)
        end
      end

      context 'access expiry date' do
        subject do
          put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer),
              params: { expires_at: expires_at, access_level: Member::MAINTAINER }
        end

        context 'when set to a date in the past' do
          let(:expires_at) { 2.days.ago.to_date }

          it 'does not update the member' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq({ 'expires_at' => ['cannot be a date in the past'] })
          end
        end

        context 'when set to a date in the future' do
          let(:expires_at) { 2.days.from_now.to_date }

          it 'updates the member' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['expires_at']).to eq(expires_at.to_s)
          end
        end
      end

      it 'returns 409 if member does not exist' do
        put api("/#{source_type.pluralize}/#{source.id}/members/123", maintainer),
            params: { access_level: Member::MAINTAINER }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 400 when access_level is not given' do
        put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer)

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'returns 400 when access level is not valid' do
        put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer),
            params: { access_level: non_existing_record_access_level }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  shared_examples 'DELETE /:source_type/:id/members/:user_id' do |source_type|
    context "with :source_type == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a member and deleting themself' do
        it 'deletes the member' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", developer)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.members.count }.by(-1)
        end
      end

      context 'when authenticated as a maintainer/owner' do
        context 'and member is a requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/members/#{access_requester.id}", maintainer)

              expect(response).to have_gitlab_http_status(:not_found)
            end.not_to change { source.requesters.count }
          end
        end

        it 'deletes the member' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.members.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", maintainer) }
        end
      end

      it 'returns 404 if member does not exist' do
        delete api("/#{source_type.pluralize}/#{source.id}/members/123", maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /groups/:id/members/:user_id' do
    let(:other_user) { create(:user) }
    let(:nested_group) { create(:group, parent: group) }

    before do
      nested_group.add_developer(developer)
      nested_group.add_developer(other_user)
    end

    it 'deletes only the member with skip_subresources=true' do
      expect do
        delete api("/groups/#{group.id}/members/#{developer.id}", maintainer), params: { skip_subresources: true }

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { group.members.count }.by(-1)
          .and change { nested_group.members.count }.by(0)
    end

    it 'deletes member and its sub memberships with skip_subresources=false' do
      expect do
        delete api("/groups/#{group.id}/members/#{developer.id}", maintainer), params: { skip_subresources: false }

        expect(response).to have_gitlab_http_status(:no_content)
      end.to change { group.members.count }.by(-1)
          .and change { nested_group.members.count }.by(-1)
    end
  end

  [false, true].each do |all|
    it_behaves_like 'GET /:source_type/:id/members/(all)', 'project', all do
      let(:source) { project }
    end

    it_behaves_like 'GET /:source_type/:id/members/(all)', 'group', all do
      let(:source) { group }
    end
  end

  [false, true].each do |all|
    it_behaves_like 'GET /:source_type/:id/members/(all/):user_id', 'project', all do
      let(:source) { all ? create(:project, :public, group: group) : project }
    end

    it_behaves_like 'GET /:source_type/:id/members/(all/):user_id', 'group', all do
      let(:source) { all ? create(:group, parent: group) : group }
    end
  end

  describe 'POST /projects/:id/members' do
    it_behaves_like 'POST /:source_type/:id/members', 'project' do
      let(:source) { project }
    end

    context 'adding owner to project' do
      it 'returns 403' do
        expect do
          post api("/projects/#{project.id}/members", maintainer),
               params: { user_id: stranger.id, access_level: Member::OWNER }

          expect(response).to have_gitlab_http_status(:bad_request)
        end.not_to change { project.members.count }
      end
    end

    context 'remove bot from project' do
      it 'returns a 403 forbidden' do
        project_bot = create(:user, :project_bot)
        create(:project_member, project: project, user: project_bot)

        expect do
          delete api("/projects/#{project.id}/members/#{project_bot.id}", maintainer)

          expect(response).to have_gitlab_http_status(:forbidden)
        end.not_to change { project.members.count }
      end
    end
  end

  it_behaves_like 'POST /:source_type/:id/members', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'PUT /:source_type/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'PUT /:source_type/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'DELETE /:source_type/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'DELETE /:source_type/:id/members/:user_id', 'group' do
    let(:source) { group }
  end
end
