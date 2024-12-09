# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VirtualRegistries::Packages::Maven::Registries, :aggregate_failures, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include_context 'for maven virtual registry api setup'

  describe 'GET /api/v4/groups/:id/-/virtual_registries/packages/maven/registries' do
    let(:group_id) { group.id }
    let(:url) { "/groups/#{group_id}/-/virtual_registries/packages/maven/registries" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(registry.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid group_id' do
      it_behaves_like 'successful response'
    end

    context 'with invalid group_id' do
      where(:group_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :not_found
        ''                     | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :not_found
      end

      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :deploy_token          | :header     | :ok
        :job_token             | :header     | :ok
      end

      with_them do
        let(:headers) { token_header(token) }

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'POST /api/v4/groups/:id/-/virtual_registries/packages/maven/registries' do
    let_it_be(:registry_class) { ::VirtualRegistries::Packages::Maven::Registry }
    let(:group_id) { group.id }
    let(:url) { "/groups/#{group_id}/-/virtual_registries/packages/maven/registries" }

    subject(:api_request) { post api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { registry_class.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(Gitlab::Json.parse(response.body)).to eq(registry_class.last.as_json)
      end
    end

    context 'with valid group_id' do
      it { is_expected.to have_request_urgency(:low) }

      it_behaves_like 'disabled virtual_registry_maven feature flag'
      it_behaves_like 'maven virtual registry disabled dependency proxy'
      it_behaves_like 'maven virtual registry not authenticated user'

      where(:user_role, :status) do
        :owner      | :created
        :maintainer | :created
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          registry_class.for_group(group).delete_all
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end

      context 'with existing registry' do
        before_all do
          group.add_maintainer(user)
        end

        it 'returns a bad request' do
          api_request

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response).to eq({ 'message' => { 'group' => ['has already been taken'] } })
        end
      end

      context 'for authentication' do
        before_all do
          group.add_maintainer(user)
        end

        before do
          registry_class.for_group(group).delete_all
        end

        where(:token, :sent_as, :status) do
          :personal_access_token | :header     | :created
          :deploy_token          | :header     | :forbidden
          :job_token             | :header     | :created
        end

        with_them do
          let(:headers) { token_header(token) }

          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid group_id' do
      before_all do
        group.add_maintainer(user)
      end

      where(:group_id, :status) do
        non_existing_record_id  | :not_found
        'foo'                   | :not_found
        ''                      | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with subgroup' do
      let(:subgroup) { create(:group, parent: group, visibility_level: group.visibility_level) }

      let(:group_id) { subgroup.id }

      before_all do
        group.add_maintainer(user)
      end

      it 'returns a bad request because it is not a top level group' do
        api_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => { 'group' => ['must be a top level Group'] } })
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(registry.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid registry_id' do
      it_behaves_like 'successful response'
    end

    context 'with invalid registry_id' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non member user' do
      let_it_be(:user) { create(:user) }

      where(:group_access_level, :status) do
        'PUBLIC'   | :forbidden
        'INTERNAL' | :forbidden
        'PRIVATE'  | :forbidden
      end
      with_them do
        before do
          group.update!(visibility_level: Gitlab::VisibilityLevel.const_get(group_access_level, false))
        end

        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :ok
        :deploy_token          | :header     | :ok
        :job_token             | :header     | :ok
      end

      with_them do
        let(:headers) { token_header(token) }

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/registries/:id' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}" }

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { ::VirtualRegistries::Packages::Maven::Registry.count }.by(-1)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid registry_id' do
      where(:user_role, :status) do
        :owner      | :no_content
        :maintainer | :no_content
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid registry_id' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :no_content
        :deploy_token          | :header     | :forbidden
        :job_token             | :header     | :no_content
      end

      with_them do
        let(:headers) { token_header(token) }

        it_behaves_like 'returning response status', params[:status]
      end
    end
  end
end
