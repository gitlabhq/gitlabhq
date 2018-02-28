require 'spec_helper'

describe API::AccessRequests do
  set(:master) { create(:user) }
  set(:developer) { create(:user) }
  set(:access_requester) { create(:user) }
  set(:stranger) { create(:user) }

  set(:project) do
    create(:project, :public, :access_requestable, creator_id: master.id, namespace: master.namespace) do |project|
      project.add_developer(developer)
      project.add_master(master)
      project.request_access(access_requester)
    end
  end

  set(:group) do
    create(:group, :public, :access_requestable) do |group|
      group.add_developer(developer)
      group.add_owner(master)
      group.request_access(access_requester)
    end
  end

  shared_examples 'GET /:sources/:id/access_requests' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger) }
      end

      context 'when authenticated as a non-master/owner' do
        %i[developer access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              get api("/#{source_type.pluralize}/#{source.id}/access_requests", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'returns access requesters' do
          get api("/#{source_type.pluralize}/#{source.id}/access_requests", master)

          expect(response).to have_gitlab_http_status(200)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(1)
        end
      end
    end
  end

  shared_examples 'POST /:sources/:id/access_requests' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger) }
      end

      context 'when authenticated as a member' do
        %i[developer master].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              expect do
                user = public_send(type)
                post api("/#{source_type.pluralize}/#{source.id}/access_requests", user)

                expect(response).to have_gitlab_http_status(403)
              end.not_to change { source.requesters.count }
            end
          end
        end
      end

      context 'when authenticated as an access requester' do
        it 'returns 400' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/access_requests", access_requester)

            expect(response).to have_gitlab_http_status(400)
          end.not_to change { source.requesters.count }
        end
      end

      context 'when authenticated as a stranger' do
        context "when access request is disabled for the #{source_type}" do
          before do
            source.update_attributes(request_access_enabled: false)
          end

          it 'returns 403' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger)

              expect(response).to have_gitlab_http_status(403)
            end.not_to change { source.requesters.count }
          end
        end

        it 'returns 201' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger)

            expect(response).to have_gitlab_http_status(201)
          end.to change { source.requesters.count }.by(1)

          # User attributes
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['name']).to eq(stranger.name)
          expect(json_response['username']).to eq(stranger.username)
          expect(json_response['state']).to eq(stranger.state)
          expect(json_response['avatar_url']).to eq(stranger.avatar_url)
          expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(stranger))

          # Member attributes
          expect(json_response['requested_at']).to be_present
        end
      end
    end
  end

  shared_examples 'PUT /:sources/:id/access_requests/:user_id/approve' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", stranger) }
      end

      context 'when authenticated as a non-master/owner' do
        %i[developer access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'returns 201' do
          expect do
            put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", master),
                access_level: Member::MASTER

            expect(response).to have_gitlab_http_status(201)
          end.to change { source.members.count }.by(1)
          # User attributes
          expect(json_response['id']).to eq(access_requester.id)
          expect(json_response['name']).to eq(access_requester.name)
          expect(json_response['username']).to eq(access_requester.username)
          expect(json_response['state']).to eq(access_requester.state)
          expect(json_response['avatar_url']).to eq(access_requester.avatar_url)
          expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(access_requester))

          # Member attributes
          expect(json_response['access_level']).to eq(Member::MASTER)
        end

        context 'user_id does not match an existing access requester' do
          it 'returns 404' do
            expect do
              put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{stranger.id}/approve", master)

              expect(response).to have_gitlab_http_status(404)
            end.not_to change { source.members.count }
          end
        end
      end
    end
  end

  shared_examples 'DELETE /:sources/:id/access_requests/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", stranger) }
      end

      context 'when authenticated as a non-master/owner' do
        %i[developer stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as the access requester' do
        it 'deletes the access requester' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", access_requester)

            expect(response).to have_gitlab_http_status(204)
          end.to change { source.requesters.count }.by(-1)
        end
      end

      context 'when authenticated as a master/owner' do
        it 'deletes the access requester' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", master)

            expect(response).to have_gitlab_http_status(204)
          end.to change { source.requesters.count }.by(-1)
        end

        context 'user_id matches a member, not an access requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{developer.id}", master)

              expect(response).to have_gitlab_http_status(404)
            end.not_to change { source.requesters.count }
          end
        end

        context 'user_id does not match an existing access requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{stranger.id}", master)

              expect(response).to have_gitlab_http_status(404)
            end.not_to change { source.requesters.count }
          end
        end
      end
    end
  end

  it_behaves_like 'GET /:sources/:id/access_requests', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/access_requests', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'POST /:sources/:id/access_requests', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'POST /:sources/:id/access_requests', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'PUT /:sources/:id/access_requests/:user_id/approve', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'PUT /:sources/:id/access_requests/:user_id/approve', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'DELETE /:sources/:id/access_requests/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'DELETE /:sources/:id/access_requests/:user_id', 'group' do
    let(:source) { group }
  end
end
