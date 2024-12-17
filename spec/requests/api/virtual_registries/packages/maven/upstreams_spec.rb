# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VirtualRegistries::Packages::Maven::Upstreams, :aggregate_failures, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include_context 'for maven virtual registry api setup'

  describe 'GET /api/v4/virtual_registries/packages/maven/registries/:id/upstreams' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}/upstreams" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(registry.upstream.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid registry' do
      it_behaves_like 'successful response'
    end

    context 'with invalid registry' do
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

  describe 'POST /api/v4/virtual_registries/packages/maven/registries/:id/upstreams' do
    let(:registry_id) { registry.id }
    let(:url) { "/virtual_registries/packages/maven/registries/#{registry_id}/upstreams" }
    let(:params) { { url: 'http://example.com' } }

    subject(:api_request) { post api(url), headers: headers, params: params }

    shared_examples 'successful response' do
      let(:upstream_model) { ::VirtualRegistries::Packages::Maven::Upstream }

      it 'returns a successful response' do
        expect { api_request }.to change { upstream_model.count }.by(1)
          .and change { ::VirtualRegistries::Packages::Maven::RegistryUpstream.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(Gitlab::Json.parse(response.body)).to eq(upstream_model.last.as_json)
        expect(upstream_model.last.cache_validity_hours).to eq(
          params[:cache_validity_hours] || upstream_model.new.cache_validity_hours
        )
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid params' do
      where(:user_role, :status) do
        :owner      | :created
        :maintainer | :created
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          registry.upstream&.destroy!
          group.send(:"add_#{user_role}", user)
        end

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with invalid registry' do
      where(:registry_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :not_found
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'for params' do
      where(:params, :status) do
        { url: 'http://example.com', username: 'test', password: 'test', cache_validity_hours: 3 } | :created
        { url: 'http://example.com', username: 'test', password: 'test' }                          | :created
        { url: '', username: 'test', password: 'test' }                                            | :bad_request
        { url: 'http://example.com', username: 'test' }                                            | :bad_request
        {}                                                                                         | :bad_request
      end

      before do
        registry.upstream&.destroy!
      end

      before_all do
        group.add_maintainer(user)
      end

      with_them do
        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'with existing upstream' do
      before_all do
        group.add_maintainer(user)
        create(:virtual_registries_packages_maven_upstream, registry: registry)
      end

      it_behaves_like 'returning response status', :conflict
    end

    context 'for authentication' do
      before_all do
        group.add_maintainer(user)
      end

      before do
        registry.upstream&.destroy!
      end

      where(:token, :sent_as, :status) do
        :personal_access_token | :header     | :created
        :deploy_token          | :header     | :forbidden
        :job_token             | :header     | :created
      end

      with_them do
        let(:headers) { token_header(token) }

        if params[:status] == :created
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end
  end

  describe 'GET /api/v4/virtual_registries/packages/maven/upstreams/:id' do
    let(:url) { "/virtual_registries/packages/maven/upstreams/#{upstream.id}" }

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to eq(registry.upstream.as_json)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with valid params' do
      it_behaves_like 'successful response'
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

  describe 'PATCH /api/v4/virtual_registries/packages/maven/upstreams/:id' do
    let(:url) { "/virtual_registries/packages/maven/upstreams/#{upstream.id}" }

    subject(:api_request) { patch api(url), params: params, headers: headers }

    context 'with valid params' do
      let(:params) { { url: 'http://example.com', username: 'test', password: 'test' } }

      it { is_expected.to have_request_urgency(:low) }

      it_behaves_like 'disabled virtual_registry_maven feature flag'
      it_behaves_like 'maven virtual registry disabled dependency proxy'
      it_behaves_like 'maven virtual registry not authenticated user'

      where(:user_role, :status) do
        :owner      | :ok
        :maintainer | :ok
        :developer  | :forbidden
        :reporter   | :forbidden
        :guest      | :forbidden
      end

      with_them do
        before do
          group.send(:"add_#{user_role}", user)
        end

        it_behaves_like 'returning response status', params[:status]
      end

      context 'for authentication' do
        before_all do
          group.add_maintainer(user)
        end

        where(:token, :sent_as, :status) do
          :personal_access_token | :header     | :ok
          :deploy_token          | :header     | :forbidden
          :job_token             | :header     | :ok
        end

        with_them do
          let(:headers) { token_header(token) }

          it_behaves_like 'returning response status', params[:status]
        end
      end
    end

    context 'for params' do
      before_all do
        group.add_maintainer(user)
      end

      let(:params) do
        { url: param_url, username: username, password: password, cache_validity_hours: cache_validity_hours }.compact
      end

      where(:param_url, :username, :password, :cache_validity_hours, :status) do
        nil                  | 'test' | 'test' | 3   | :ok
        'http://example.com' | nil    | 'test' | 3   | :ok
        'http://example.com' | 'test' | nil    | 3   | :ok
        'http://example.com' | 'test' | 'test' | nil | :ok
        nil                  | nil    | nil    | 3   | :ok
        'http://example.com' | 'test' | 'test' | 3   | :ok
        ''                   | 'test' | 'test' | 3   | :bad_request
        'http://example.com' | ''     | 'test' | 3   | :bad_request
        'http://example.com' | 'test' | ''     | 3   | :bad_request
        'http://example.com' | 'test' | 'test' | -1  | :bad_request
        nil                  | nil    | nil    | nil | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/upstreams/:id' do
    let(:url) { "/virtual_registries/packages/maven/upstreams/#{upstream.id}" }

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change { ::VirtualRegistries::Packages::Maven::Upstream.count }.by(-1)
          .and change { ::VirtualRegistries::Packages::Maven::RegistryUpstream.count }.by(-1)
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'for different user roles' do
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

        if params[:status] == :no_content
          it_behaves_like 'successful response'
        else
          it_behaves_like 'returning response status', params[:status]
        end
      end
    end
  end
end
