# frozen_string_literal: true

require 'spec_helper'

describe API::Badges do
  let(:maintainer) { create(:user, username: 'maintainer_user') }
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

      %i[maintainer developer access_requester stranger].each do |type|
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
        get api("/#{source_type.pluralize}/#{source.id}/badges", maintainer)

        control = ActiveRecord::QueryRecorder.new do
          get api("/#{source_type.pluralize}/#{source.id}/badges", maintainer)
        end

        project.add_developer(create(:user))

        expect do
          get api("/#{source_type.pluralize}/#{source.id}/badges", maintainer)
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
        %i[maintainer developer access_requester stranger].each do |type|
          let(:badge) { source.badges.first }

          context "as a #{type}" do
            it 'returns 200', :quarantine do
              user = public_send(type)

              get api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", user)

              expect(response).to have_gitlab_http_status(200)
              expect(json_response['name']).to eq(badge.name)
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
    let(:example_name) { 'BadgeName' }
    let(:example_url) { 'http://www.example.com' }
    let(:example_url2) { 'http://www.example1.com' }

    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          post api("/#{source_type.pluralize}/#{source.id}/badges", stranger),
               params: { name: example_name, link_url: example_url, image_url: example_url2 }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              post api("/#{source_type.pluralize}/#{source.id}/badges", user),
                   params: { link_url: example_url, image_url: example_url2 }

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'creates a new badge' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/badges", maintainer),
                params: { name: example_name, link_url: example_url, image_url: example_url2 }

            expect(response).to have_gitlab_http_status(201)
          end.to change { source.badges.count }.by(1)

          expect(json_response['name']).to eq(example_name)
          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['kind']).to eq source_type
        end
      end

      it 'returns 400 when link_url is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", maintainer),
             params: { link_url: example_url }

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when image_url is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", maintainer),
             params: { image_url: example_url2 }

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when link_url or image_url is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/badges", maintainer),
             params: { link_url: 'whatever', image_url: 'whatever' }

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  shared_examples 'PUT /:sources/:id/badges/:badge_id' do |source_type|
    include_context 'source helpers'

    let(:source) { get_source(source_type) }

    context "with :sources == #{source_type.pluralize}" do
      let(:badge) { source.badges.first }
      let(:example_name) { 'BadgeName' }
      let(:example_url) { 'http://www.example.com' }
      let(:example_url2) { 'http://www.example1.com' }

      it_behaves_like 'a 404 response when source is private' do
        let(:route) do
          put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", stranger),
              params: { link_url: example_url }
        end
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)

              put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", user),
                  params: { link_url: example_url }

              expect(response).to have_gitlab_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'updates the member', :quarantine do
          put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", maintainer),
              params: { name: example_name, link_url: example_url, image_url: example_url2 }

          expect(response).to have_gitlab_http_status(200)
          expect(json_response['name']).to eq(example_name)
          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['kind']).to eq source_type
        end
      end

      it 'returns 400 when link_url or image_url is not valid' do
        put api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", maintainer),
            params: { link_url: 'whatever', image_url: 'whatever' }

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

      context 'when authenticated as a maintainer/owner', :quarantine do
        it 'deletes the badge' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", maintainer)

            expect(response).to have_gitlab_http_status(204)
          end.to change { source.badges.count }.by(-1)
        end

        it_behaves_like '412 response' do
          let(:request) { api("/#{source_type.pluralize}/#{source.id}/badges/#{badge.id}", maintainer) }
        end
      end

      it 'returns 404 if badge does not exist' do
        delete api("/#{source_type.pluralize}/#{source.id}/badges/123", maintainer)

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

      context 'when authenticated as a maintainer/owner' do
        it 'gets the rendered badge values' do
          get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}&image_url=#{example_url2}", maintainer)

          expect(response).to have_gitlab_http_status(200)

          expect(json_response.keys).to contain_exactly('name', 'link_url', 'rendered_link_url', 'image_url', 'rendered_image_url')
          expect(json_response['link_url']).to eq(example_url)
          expect(json_response['image_url']).to eq(example_url2)
          expect(json_response['rendered_link_url']).to eq(example_url)
          expect(json_response['rendered_image_url']).to eq(example_url2)
        end
      end

      it 'returns 400 when link_url is not given' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=#{example_url}", maintainer)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when image_url is not given' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?image_url=#{example_url}", maintainer)

        expect(response).to have_gitlab_http_status(400)
      end

      it 'returns 400 when link_url or image_url is not valid' do
        get api("/#{source_type.pluralize}/#{source.id}/badges/render?link_url=whatever&image_url=whatever", maintainer)

        expect(response).to have_gitlab_http_status(400)
      end
    end
  end

  context 'when deleting a badge' do
    context 'and the source is a project' do
      it 'cannot delete badges owned by the project group' do
        delete api("/projects/#{project.id}/badges/#{project_group.badges.first.id}", maintainer)

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
    create(:project, :public, creator_id: maintainer.id, namespace: project_group) do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.request_access(access_requester)
      project.project_badges << build(:project_badge, project: project, name: 'ExampleBadge1')
      project.project_badges << build(:project_badge, project: project, name: 'ExampleBadge2')
      project_group.badges << build(:group_badge, group: group, name: 'ExampleBadge3')
    end
  end

  def setup_group
    create(:group, :public) do |group|
      group.add_developer(developer)
      group.add_owner(maintainer)
      group.request_access(access_requester)
      group.badges << build(:group_badge, group: group, name: 'ExampleBadge4')
      group.badges << build(:group_badge, group: group, name: 'ExampleBadge5')
    end
  end
end
