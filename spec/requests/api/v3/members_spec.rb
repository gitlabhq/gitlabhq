require 'spec_helper'

describe API::V3::Members do
  let(:master) { create(:user, username: 'master_user') }
  let(:developer) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:stranger) { create(:user) }

  let(:project) do
    create(:project, :public, :access_requestable, creator_id: master.id, namespace: master.namespace) do |project|
      project.add_developer(developer)
      project.add_master(master)
      project.request_access(access_requester)
    end
  end

  let!(:group) do
    create(:group, :public, :access_requestable) do |group|
      group.add_developer(developer)
      group.add_owner(master)
      group.request_access(access_requester)
    end
  end

  shared_examples 'GET /:sources/:id/members' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get v3_api("/#{source_type.pluralize}/#{source.id}/members", stranger) }
      end

      %i[master developer access_requester stranger].each do |type|
        context "when authenticated as a #{type}" do
          it 'returns 200' do
            user = public_send(type)
            get v3_api("/#{source_type.pluralize}/#{source.id}/members", user)

            expect(response).to have_gitlab_http_status(200)
            expect(json_response.size).to eq(2)
            expect(json_response.map { |u| u['id'] }).to match_array [master.id, developer.id]
          end
        end
      end

      it 'does not return invitees' do
        create(:"#{source_type}_member", invite_token: '123', invite_email: 'test@abc.com', source: source, user: nil)

        get v3_api("/#{source_type.pluralize}/#{source.id}/members", developer)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.size).to eq(2)
        expect(json_response.map { |u| u['id'] }).to match_array [master.id, developer.id]
      end

      it 'finds members with query string' do
        get v3_api("/#{source_type.pluralize}/#{source.id}/members", developer), query: master.username

        expect(response).to have_gitlab_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['username']).to eq(master.username)
      end

      it 'finds all members with no query specified' do
        get v3_api("/#{source_type.pluralize}/#{source.id}/members", developer), query: ''

        expect(response).to have_gitlab_http_status(200)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.count).to eq(2)
        expect(json_response.map { |u| u['id'] }).to match_array [master.id, developer.id]
      end
    end
  end

  shared_examples 'GET /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 200' do
              user = public_send(type)
              get v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_gitlab_http_status(200)
              # User attributes
              expect(json_response['id']).to eq(developer.id)
              expect(json_response['name']).to eq(developer.name)
              expect(json_response['username']).to eq(developer.username)
              expect(json_response['state']).to eq(developer.state)
              expect(json_response['avatar_url']).to eq(developer.avatar_url)
              expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(developer))

              # Member attributes
              expect(json_response['access_level']).to eq(Member::DEVELOPER)
            end
          end
        end
      end
    end
  end

  shared_examples 'POST /:sources/:id/members' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post v3_api("/#{source_type.pluralize}/#{source.id}/members", stranger),
               user_id: access_requester.id, access_level: Member::MASTER
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              post v3_api("/#{source_type.pluralize}/#{source.id}/members", user),
                   user_id: access_requester.id, access_level: Member::MASTER

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        context 'and new member is already a requester' do
          it 'transforms the requester into a proper member' do
            expect do
              post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
                   user_id: access_requester.id, access_level: Member::MASTER

              expect(response).to have_gitlab_http_status(201)
            end.to change { source.members.count }.by(1)
            expect(source.requesters.count).to eq(0)
            expect(json_response['id']).to eq(access_requester.id)
            expect(json_response['access_level']).to eq(Member::MASTER)
          end
        end

        it 'creates a new member' do
          expect do
            post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
                 user_id: stranger.id, access_level: Member::DEVELOPER, expires_at: '2016-08-05'

            expect(response).to have_gitlab_http_status(201)
          end.to change { source.members.count }.by(1)
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['access_level']).to eq(Member::DEVELOPER)
          expect(json_response['expires_at']).to eq('2016-08-05')
        end
      end

      it "returns #{source_type == 'project' ? 201 : 409} if member already exists" do
        post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: master.id, access_level: Member::MASTER

        expect(response).to have_gitlab_http_status(source_type == 'project' ? 201 : 409)
      end

      it 'returns 400 when user_id is not given' do
        post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
             access_level: Member::MASTER

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when access_level is not given' do
        post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: stranger.id

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 422 when access_level is not valid' do
        post v3_api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: stranger.id, access_level: 1234

        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  shared_examples 'PUT /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          put v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger),
              access_level: Member::MASTER
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              put v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user),
                  access_level: Member::MASTER

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'updates the member' do
          put v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master),
              access_level: Member::MASTER, expires_at: '2016-08-05'

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['id']).to eq(developer.id)
          expect(json_response['access_level']).to eq(Member::MASTER)
          expect(json_response['expires_at']).to eq('2016-08-05')
        end
      end

      it 'returns 409 if member does not exist' do
        put v3_api("/#{source_type.pluralize}/#{source.id}/members/123", master),
            access_level: Member::MASTER

        expect(response).to have_gitlab_http_status(404)
      end

      it 'returns 400 when access_level is not given' do
        put v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 422 when access level is not valid' do
        put v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master),
            access_level: 1234

        expect(response).to have_gitlab_http_status(422)
      end
    end
  end

  shared_examples 'DELETE /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              delete v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a member and deleting themself' do
        it 'deletes the member' do
          expect do
            delete v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", developer)

            expect(response).to have_gitlab_http_status(200)
          end.to change { source.members.count }.by(-1)
        end
      end

      context 'when authenticated as a master/owner' do
        context 'and member is a requester' do
          it "returns #{source_type == 'project' ? 200 : 404}" do
            expect do
              delete v3_api("/#{source_type.pluralize}/#{source.id}/members/#{access_requester.id}", master)

              expect(response).to have_gitlab_http_status(source_type == 'project' ? 200 : 404)
            end.not_to change { source.requesters.count }
          end
        end

        it 'deletes the member' do
          expect do
            delete v3_api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master)

            expect(response).to have_gitlab_http_status(200)
          end.to change { source.members.count }.by(-1)
        end
      end

      it "returns #{source_type == 'project' ? 200 : 404} if member does not exist" do
        delete v3_api("/#{source_type.pluralize}/#{source.id}/members/123", master)

        expect(response).to have_gitlab_http_status(source_type == 'project' ? 200 : 404)
      end
    end
  end

  it_behaves_like 'GET /:sources/:id/members', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/members', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'GET /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'POST /:sources/:id/members', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'POST /:sources/:id/members', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'PUT /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'PUT /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'DELETE /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'DELETE /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  context 'Adding owner to project' do
    it 'returns 403' do
      expect do
        post v3_api("/projects/#{project.id}/members", master),
             user_id: stranger.id, access_level: Member::OWNER

        expect(response).to have_gitlab_http_status(422)
      end.to change { project.members.count }.by(0)
    end
  end
end
