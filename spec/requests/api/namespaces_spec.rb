# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Namespaces, feature_category: :subgroups do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:group1) { create(:group, name: 'group.one') }
  let_it_be(:group2) { create(:group, :nested) }
  let_it_be(:project) { create(:project, namespace: group2, name: group2.name, path: group2.path) }
  let_it_be(:project_namespace) { project.project_namespace }

  describe "GET /namespaces" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/namespaces")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when authenticated as admin" do
      it "returns correct attributes" do
        get api("/namespaces", admin)

        group_kind_json_response = json_response.find { |resource| resource['kind'] == 'group' }
        user_kind_json_response = json_response.find { |resource| resource['kind'] == 'user' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(group_kind_json_response.keys).to include('id', 'kind', 'name', 'path', 'full_path',
          'parent_id', 'members_count_with_descendants')

        expect(user_kind_json_response.keys).to include('id', 'kind', 'name', 'path', 'full_path', 'parent_id')
      end

      it "admin: returns an array of all namespaces" do
        get api("/namespaces", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        # project namespace is excluded
        expect(json_response.length).to eq(Namespace.count - 1)
      end

      it "admin: returns an array of matched namespaces" do
        get api("/namespaces?search=#{group2.name}", admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.last['path']).to eq(group2.path)
        expect(json_response.last['full_path']).to eq(group2.full_path)
      end
    end

    context "when authenticated as a regular user" do
      it "returns correct attributes when user can admin group" do
        group1.add_owner(user)

        get api("/namespaces", user)

        owned_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(owned_group_response.keys).to include('id', 'kind', 'name', 'path', 'full_path',
          'parent_id', 'members_count_with_descendants')
      end

      it "returns correct attributes when user cannot admin group" do
        group1.add_guest(user)

        get api("/namespaces", user)

        guest_group_response = json_response.find { |resource| resource['id'] == group1.id }

        expect(guest_group_response.keys).to include('id', 'kind', 'name', 'path', 'full_path', 'parent_id')
      end

      it "user: returns an array of namespaces" do
        get api("/namespaces", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      it "admin: returns an array of matched namespaces" do
        get api("/namespaces?search=#{user.username}", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
      end

      context 'with owned_only param' do
        it 'returns only owned groups' do
          group1.add_developer(user)
          group2.add_owner(user)

          get api("/namespaces?owned_only=true", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response.map { |resource| resource['id'] }).to match_array([user.namespace_id, group2.id])
        end
      end
    end
  end

  describe 'GET /namespaces/:id' do
    let(:owned_group) { group1 }

    let_it_be(:user2) { create(:user) }

    shared_examples 'can access namespace' do
      it 'returns namespace details' do
        get api("/namespaces/#{namespace_id}", request_actor)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['id']).to eq(requested_namespace.id)
        expect(json_response['path']).to eq(requested_namespace.path)
        expect(json_response['name']).to eq(requested_namespace.name)
      end
    end

    shared_examples 'namespace reader' do
      let(:requested_namespace) { owned_group }

      before do
        owned_group.add_owner(request_actor)
      end

      context 'when namespace exists' do
        context 'when requested by ID' do
          context 'when requesting group' do
            let(:namespace_id) { owned_group.id }

            it_behaves_like 'can access namespace'
          end

          context 'when requesting personal namespace' do
            let(:namespace_id) { request_actor.namespace.id }
            let(:requested_namespace) { request_actor.namespace }

            it_behaves_like 'can access namespace'
          end

          context 'when requesting project_namespace' do
            let(:namespace_id) { project_namespace.id }

            it 'returns not-found' do
              get api("/namespaces/#{namespace_id}", request_actor)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end

        context 'when requested by path' do
          context 'when requesting group' do
            let(:namespace_id) { owned_group.path }

            it_behaves_like 'can access namespace'
          end

          context 'when requesting personal namespace' do
            let(:namespace_id) { request_actor.namespace.path }
            let(:requested_namespace) { request_actor.namespace }

            it_behaves_like 'can access namespace'
          end

          context 'when requesting project_namespace' do
            let(:namespace_id) { project_namespace.full_path }

            it 'returns not-found' do
              get api("/namespaces/#{namespace_id}", request_actor)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end

      context "when namespace doesn't exist" do
        it 'returns not-found' do
          get api('/namespaces/0', request_actor)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/namespaces/#{group1.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'returns authentication error' do
        get api("/namespaces/#{project_namespace.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as regular user' do
      let(:request_actor) { user }

      context 'when requested namespace is not owned by user' do
        context 'when requesting group' do
          it 'returns not-found' do
            get api("/namespaces/#{group2.id}", request_actor)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when requesting personal namespace' do
          it 'returns not-found' do
            get api("/namespaces/#{user2.namespace.id}", request_actor)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when requested namespace is owned by user' do
        it_behaves_like 'namespace reader'
      end
    end

    context 'when authenticated as admin' do
      let(:request_actor) { admin }

      context 'when requested namespace is not owned by user' do
        context 'when requesting group' do
          let(:namespace_id) { group2.id }
          let(:requested_namespace) { group2 }

          it_behaves_like 'can access namespace'
        end

        context 'when requesting personal namespace' do
          let(:namespace_id) { user2.namespace.id }
          let(:requested_namespace) { user2.namespace }

          it_behaves_like 'can access namespace'
        end
      end

      context 'when requested namespace is owned by user' do
        it_behaves_like 'namespace reader'
      end
    end
  end

  describe 'GET /namespaces/:namespace/exists' do
    let_it_be(:namespace1) { create(:group, name: 'Namespace 1', path: 'namespace-1') }
    let_it_be(:namespace2) { create(:group, name: 'Namespace 2', path: 'namespace-2') }
    let_it_be(:namespace_with_dot) { create(:group, name: 'With Dot', path: 'with.dot') }
    let_it_be(:namespace1sub) { create(:group, name: 'Sub Namespace 1', path: 'sub-namespace-1', parent: namespace1) }
    let_it_be(:namespace2sub) { create(:group, name: 'Sub Namespace 2', path: 'sub-namespace-2', parent: namespace2) }

    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api("/namespaces/#{namespace1.path}/exists")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      context 'when requesting project_namespace' do
        let(:namespace_id) { project_namespace.id }

        it 'returns authentication error' do
          get api("/namespaces/#{project_namespace.path}/exists"), params: { parent_id: group2.id }

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated' do
      it_behaves_like 'rate limited endpoint', rate_limit_key: :namespace_exists do
        let(:current_user) { user }

        def request
          get api("/namespaces/#{namespace1.path}/exists", current_user)
        end
      end

      it 'returns JSON indicating the namespace exists and a suggestion' do
        get api("/namespaces/#{namespace1.path}/exists", user)

        expected_json = { exists: true, suggests: ["#{namespace1.path}1"] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'supports dot in namespace path' do
        get api("/namespaces/#{namespace_with_dot.path}/exists", user)

        expected_json = { exists: true, suggests: ["#{namespace_with_dot.path}1"] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'returns JSON indicating the namespace does not exist without a suggestion' do
        get api("/namespaces/non-existing-namespace/exists", user)

        expected_json = { exists: false, suggests: [] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'checks the existence of a namespace in case-insensitive manner' do
        get api("/namespaces/#{namespace1.path.upcase}/exists", user)

        expected_json = { exists: true, suggests: ["#{namespace1.path.upcase}1"] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'checks the existence within the parent namespace only' do
        get api("/namespaces/#{namespace1sub.path}/exists", user), params: { parent_id: namespace1.id }

        expected_json = { exists: true, suggests: ["#{namespace1sub.path}1"] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'ignores nested namespaces when checking for top-level namespace' do
        get api("/namespaces/#{namespace1sub.path}/exists", user)

        expected_json = { exists: false, suggests: [] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'ignores paths of groups present in other hierarchies when making suggestions' do
        (1..2).to_a.each do |suffix|
          create(:group, name: "mygroup#{suffix}", path: "mygroup#{suffix}", parent: namespace2)
        end

        create(:group, name: 'mygroup', path: 'mygroup', parent: namespace1)

        get api("/namespaces/mygroup/exists", user), params: { parent_id: namespace1.id }

        # if the paths of groups present in hierachies aren't ignored, the suggestion generated would have
        # been `mygroup3`, just because groups with path `mygroup1` and `mygroup2` exists somewhere else.
        # But there is no reason for those groups that exists elsewhere to cause a conflict because
        # their hierarchies differ. Hence, the correct suggestion to be generated would be `mygroup1`
        expected_json = { exists: true, suggests: ["mygroup1"] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'ignores top-level namespaces when checking with parent_id' do
        get api("/namespaces/#{namespace1.path}/exists", user), params: { parent_id: namespace1.id }

        expected_json = { exists: false, suggests: [] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      it 'ignores namespaces of other parent namespaces when checking with parent_id' do
        get api("/namespaces/#{namespace2sub.path}/exists", user), params: { parent_id: namespace1.id }

        expected_json = { exists: false, suggests: [] }.to_json
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq(expected_json)
      end

      context 'when requesting project_namespace' do
        let(:namespace_id) { project_namespace.id }

        it 'returns JSON indicating the namespace does not exist without a suggestion' do
          get api("/namespaces/#{project_namespace.path}/exists", user), params: { parent_id: group2.id }

          expected_json = { exists: false, suggests: [] }.to_json
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to eq(expected_json)
        end
      end
    end
  end
end
