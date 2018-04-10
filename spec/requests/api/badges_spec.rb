require 'spec_helper'

describe API::Badges do
  let(:master) { create(:user, username: 'master_user') }
  let(:developer) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:stranger) { create(:user) }
  let(:project_group) { create(:group) }
  let(:project) { setup_project }
  let!(:group) { setup_group }

  shared_context 'source helpers' do
    def get_source(source_type)
      source_type == 'project' ? project : group
    end
  end

  shared_examples 'GET /:sources/:id/badges' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }

    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/badges", stranger) }
      end

      %i[master developer access_requester stranger].each do |type|
        context "when authenticated as a #{type}" do
          it 'returns 200' do
            user = public_send(type)
            badges_count = source_type == 'project' ? 3 : 2

            get api("/#{source_type.pluralize}/#{source.id}/badges", user)

            expect(response).to have_gitlab_http_status(200)
            expect(response).to include_pagination_headers
            expect(json_response).to be_an Array
            expect(json_response.size).to eq(badges_count)
          end
        end
      end

      it 'avoids N+1 queries' do
        # Establish baseline
        get api("/#{source_type.pluralize}/#{source.id}/badges", master)

        control = ActiveRecord::QueryRecorder.new do
          get api("/#{source_type.pluralize}/#{source.id}/badges", master)
        end

        project.add_developer(create(:user))

        expect do
          get api("/#{source_type.pluralize}/#{source.id}/badges", master)
        end.not_to exceed_query_limit(control)
      end
    end
  end

  shared_examples 'GET /:sources/:id/badges/:badge_id' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }

    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/badges/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member' do
        %i[master developer access_requester stranger].each do |type|
          let(:badge) { source.badges.first }

          context "as a #{type}" do
            it 'returns 200' do
              user = public_send(type)

              get api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", user)

              expect(response).to have_gitlab_http_status(200)
              expect(json_response['id']).to eq(badge.id)
              expect(json_response['link_url']).to eq(badge.link_url)
              expect(json_response['rendered_link_url']).to eq(badge.rendered_link_url)
              expect(json_response['image_url']).to eq(badge.image_url)
              expect(json_response['rendered_image_url']).to eq(badge.rendered_image_url)
              expect(json_response['kind']).to eq source_type
            end
          end
        end
      end
    end
  end

  shared_examples 'POST /:sources/:id/badges' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }
    let(:example_url) { 'http://www.example.com' }
    let(:example_url2) { 'http://www.example1.com' }

    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post api("/#{source_type.pluralize}/#{source.id}/badges", stranger),
               link_url: example_url, image_url: example_url2
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              post api("/#{source_type.pluralize}/#{source.id}/badges", user),
                   link_url: example_url, image_url: example_url2

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'creates a new badge' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/badges", master),
                link_url: example_url, image_url: example_url2

            expect(response).to have_gitlab_http_status(201)
          end.to change { source.badges.count }.by(1)

          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['kind']).to eq source_type
        end
      end

      it 'returns 400 when link_url is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", master),
             link_url: example_url

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when image_url is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", master),
             image_url: example_url2

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when link_url or image_url is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", master),
             link_url: 'whatever', image_url: 'whatever'

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  shared_examples 'PUT /:sources/:id/badges/:badge_id' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }

    context "with :sources == #{source_type.pluralize}" do
      let(:badge) { source.badges.first }
      let(:example_url) { 'http://www.example.com' }
      let(:example_url2) { 'http://www.example1.com' }

      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", stranger),
              link_url: example_url
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", user),
                  link_url: example_url

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'updates the member' do
          put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", master),
              link_url: example_url, image_url: example_url2

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['kind']).to eq source_type
        end
      end

      it 'returns 400 when link_url or image_url is not valid' do
        put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", master),
            link_url: 'whatever', image_url: 'whatever'

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  shared_examples 'DELETE /:sources/:id/badges/:badge_id' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }

    context "with :sources == #{source_type.pluralize}" do
      let(:badge) { source.badges.first }

      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester developer stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              delete api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'deletes the badge' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", master)

            expect(response).to have_gitlab_http_status(204)
          end.to change { source.badges.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", master) }
        end
      end

      it 'returns 404 if badge does not exist' do
        delete api("/#{source_type.pluralize}/#{source.id}/badges/123", master)

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  shared_examples 'GET /:sources/:id/badges/render' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }
    let(:example_url) { 'http://www.example.com' }
    let(:example_url2) { 'http://www.example1.com' }

    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}&image_url=#{example_url2}", stranger)
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}&image_url=#{example_url2}", user)

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'gets the rendered badge values' do
          get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}&image_url=#{example_url2}", master)

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.keys).to contain_exactly('link_url', 'rendered_link_url', 'image_url', 'rendered_image_url')
          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['rendered_link_url']).to eq(example_url)
          expect(json_response['rendered_image_url']).to eq(example_url2)
        end
      end

      it 'returns 400 when link_url is not given' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}", master)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when image_url is not given' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?image_url=#{example_url}", master)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when link_url or image_url is not valid' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=whatever&image_url=whatever", master)

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  context 'when deleting a badge' do
    context 'and the source is a project' do
      it 'cannot delete badges owned by the project group' do
        delete api("/projects/#{project.id}/badges/#{project_group.badges.first.id}", master)

        expect(response).to have_gitlab_http_status(403)
      end
    end
  end

  describe 'Endpoints' do
    %w(project group).each do |source_type|
      it_behaves_like 'GET /:sources/:id/badges', source_type
      it_behaves_like 'GET /:sources/:id/badges/:badge_id', source_type
      it_behaves_like 'GET /:sources/:id/badges/render', source_type
      it_behaves_like 'POST /:sources/:id/badges', source_type
      it_behaves_like 'PUT /:sources/:id/badges/:badge_id', source_type
      it_behaves_like 'DELETE /:sources/:id/badges/:badge_id', source_type
    end
  end

  def setup_project
    create(:project, :public, :access_requestable, creator_id: master.id, namespace: project_group) do |project|
      project.add_developer(developer)
      project.add_master(master)
      project.request_access(access_requester)
      project.project_badges << build(:project_badge, project: project)
      project.project_badges << build(:project_badge, project: project)
      project_group.badges << build(:group_badge, group: group)
    end
  end

  def setup_group
    create(:group, :public, :access_requestable) do |group|
      group.add_developer(developer)
      group.add_owner(master)
      group.request_access(access_requester)
      group.badges << build(:group_badge, group: group)
      group.badges << build(:group_badge, group: group)
    end
  end
end
