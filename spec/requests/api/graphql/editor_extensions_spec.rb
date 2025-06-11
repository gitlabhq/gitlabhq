# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Editor Extensions GraphQL integration', :clean_gitlab_redis_cache, feature_category: :editor_extensions do
  include GraphqlHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, organizations: [organization], developer_of: project) }
  let(:query) { graphql_query_for('project', { fullPath: project.full_path }, 'id') }

  describe 'language server client restrictions' do
    context 'with allowed clients' do
      using RSpec::Parameterized::TableSyntax

      where(:is_dedicated, :enforce_language_server_version, :enable_language_server_restrictions, :client_version,
        :user_agent) do
        false | false | false | '0.1.0' | 'gitlab-language-server 0.1.0'
        false | false | false | nil     | 'code-completions-language-server-experiment (gitlab.vim: 1.0.0)'
        false | false | false | nil     | 'gitlab-language-server 1.0.0'
        false | false | false | nil     | 'unknown-app 1.0.0'
        false | false | false | nil     | nil
        false | false | true  | '0.1.0' | 'gitlab-language-server 0.1.0'
        false | true  | true  | '1.0.0' | 'gitlab-language-server 1.0.0'
        false | true  | true  | '2.0.0' | 'gitlab-language-server 2.0.0'
        true  | false | false | '0.1.0' | 'gitlab-language-server 0.1.0'
        true  | false | false | nil     | 'code-completions-language-server-experiment (gitlab.vim: 1.0.0)'
        true  | false | false | nil     | 'gitlab-language-server 1.0.0'
        true  | false | false | nil     | 'unknown-app 1.0.0'
        true  | false | false | nil     | nil
      end

      with_them do
        before do
          stub_feature_flags(enforce_language_server_version: enforce_language_server_version)

          allow(Gitlab::CurrentSettings.current_application_settings).to receive_messages(
            enable_language_server_restrictions: enable_language_server_restrictions,
            gitlab_dedicated_instance?: is_dedicated,
            minimum_language_server_version: '1.0.0')
        end

        it 'is suppported' do
          post_graphql(query, current_user: user, headers: {
            'User-Agent' => user_agent,
            'X-GitLab-Language-Server-Version' => client_version
          })

          expect(response).to have_gitlab_http_status(:success)
          expect(graphql_data['project']['id']).to eq(project.to_gid.to_s)
        end
      end
    end

    shared_examples 'unallowed clients' do
      using RSpec::Parameterized::TableSyntax

      where(:client_version, :user_agent) do
        '0.1.0' | 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
        '0.1.0' | 'gitlab-language-server 1.0.0'
        '0.1.0' | nil
        nil     | 'code-completions-language-server-experiment (gl-visual-studio-extension:1.0.0.0; arch:X64;)'
        nil     | 'gitlab-language-server 0.1.0'
      end

      with_them do
        it 'is supported' do
          post_graphql(query, current_user: user, headers: {
            'User-Agent' => user_agent,
            'X-GitLab-Language-Server-Version' => client_version
          })

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(graphql_errors).to contain_exactly(
            hash_including('message' => a_string_including('Requests from Editor Extension clients are restricted'))
          )
        end
      end
    end

    context 'with unallowed clients on dedicated' do
      before do
        stub_feature_flags(enforce_language_server_version: false)

        allow(Gitlab::CurrentSettings.current_application_settings).to receive_messages(
          enable_language_server_restrictions: true,
          gitlab_dedicated_instance?: true,
          minimum_language_server_version: '1.0.0')
      end

      it_behaves_like 'unallowed clients'
    end

    context 'with unallowed clients outside of dedicated' do
      before do
        stub_feature_flags(enforce_language_server_version: true)

        allow(Gitlab::CurrentSettings.current_application_settings).to receive_messages(
          enable_language_server_restrictions: true,
          gitlab_dedicated_instance?: false,
          minimum_language_server_version: '1.0.0')
      end

      it_behaves_like 'unallowed clients'
    end
  end
end
