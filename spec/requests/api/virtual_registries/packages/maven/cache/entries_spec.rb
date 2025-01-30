# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::VirtualRegistries::Packages::Maven::Cache::Entries, :aggregate_failures, feature_category: :virtual_registry do
  using RSpec::Parameterized::TableSyntax
  include_context 'for maven virtual registry api setup'

  describe 'GET /api/v4/virtual_registries/packages/maven/upstreams/:id/cache_entries' do
    let(:upstream_id) { upstream.id }
    let(:url) { "/virtual_registries/packages/maven/upstreams/#{upstream_id}/cache_entries" }

    let_it_be(:processing_cache_entry) do
      create(
        :virtual_registries_packages_maven_cache_entry,
        :processing,
        upstream: upstream,
        group: upstream.group,
        relative_path: cache_entry.relative_path
      )
    end

    subject(:api_request) { get api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(Gitlab::Json.parse(response.body)).to contain_exactly(
          cache_entry
            .as_json
            .merge('id' => Base64.urlsafe_encode64("#{upstream.id} #{cache_entry.relative_path}"))
            .except('object_storage_key', 'file_store', 'status', 'file_final_path')
        )
      end
    end

    it { is_expected.to have_request_urgency(:low) }

    it_behaves_like 'disabled virtual_registry_maven feature flag'
    it_behaves_like 'maven virtual registry disabled dependency proxy'
    it_behaves_like 'maven virtual registry not authenticated user'

    context 'with invalid upstream' do
      where(:upstream_id, :status) do
        non_existing_record_id | :not_found
        'foo'                  | :bad_request
        ''                     | :bad_request
      end

      with_them do
        it_behaves_like 'returning response status', params[:status]
      end
    end

    context 'with a non-member user' do
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

    context 'for search param' do
      let(:url) { "#{super()}?search=#{search}" }
      let(:valid_search) { cache_entry.relative_path.slice(0, 5) }

      where(:search, :status) do
        ref(:valid_search) | :ok
        'foo'              | :empty
        ''                 | :ok
        nil                | :ok
      end

      with_them do
        if params[:status] == :ok
          it_behaves_like 'successful response'
        else
          it 'returns an empty array' do
            api_request

            expect(json_response).to eq([])
          end
        end
      end
    end
  end

  describe 'DELETE /api/v4/virtual_registries/packages/maven/cache_entries/:id' do
    let(:id) { Base64.urlsafe_encode64("#{upstream.id} #{cache_entry.relative_path}") }
    let(:url) { "/virtual_registries/packages/maven/cache_entries/#{id}" }

    subject(:api_request) { delete api(url), headers: headers }

    shared_examples 'successful response' do
      it 'returns a successful response' do
        expect { api_request }.to change {
          VirtualRegistries::Packages::Maven::Cache::Entry.last.status
        }.from('default').to('pending_destruction')

        expect(response).to have_gitlab_http_status(:no_content)
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

    context 'when error occurs' do
      before_all do
        group.add_maintainer(user)
      end

      before do
        allow_next_found_instance_of(cache_entry.class) do |instance|
          errors = ActiveModel::Errors.new(instance).tap { |e| e.add(:cache_entry, 'error message') }
          allow(instance).to receive_messages(mark_as_pending_destruction: false, errors: errors)
        end
      end

      it 'returns an error' do
        api_request

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq({ 'message' => { 'cache_entry' => ['error message'] } })
      end
    end
  end
end
