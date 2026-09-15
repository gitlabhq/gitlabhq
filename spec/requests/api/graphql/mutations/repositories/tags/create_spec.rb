# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a tag', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:current_user) { create(:user) }

  let(:input) { { project_path: project_path, name: tag_name, ref: ref, message: message } }
  let(:project_path) { project.full_path }
  let(:tag_name) { 'tag1' }
  let(:ref) { 'master' }
  let(:message) { '' }

  let(:mutation) { graphql_mutation(:tag_create, input) }
  let(:mutation_response) { graphql_mutation_response(:tag_create) }

  shared_examples 'creates a tag' do
    specify do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['tag']).to include(
        'name' => tag_name,
        'message' => message,
        'commit' => a_hash_including('id')
      )
      expect(mutation_response['errors']).to eq([])
    end
  end

  context 'when project is public' do
    let(:project) { create(:project, :public, :small_repo) }

    context 'when user is not allowed to create a tag' do
      it_behaves_like 'a mutation that returns a top-level access error'

      it 'does not consume the rate limit budget' do
        expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled_request?)

        post_graphql_mutation(mutation, current_user: current_user)
      end
    end

    context 'when user is a direct project member' do
      context 'and user is a developer' do
        before do
          project.add_developer(current_user)
        end

        it_behaves_like 'authorizing granular token permissions for GraphQL',
          [:create_repository_tag, :read_repository_tag] do
          let(:user) { current_user }
          let(:boundary_object) { project }
          let(:mutation) { graphql_mutation(:tag_create, input, 'tag { name message } errors') }
          let(:request) { post_graphql_mutation(mutation, token: { personal_access_token: pat }) }
        end

        it_behaves_like 'creates a tag'

        context 'when message is not provided' do
          let(:input) { { project_path: project_path, name: tag_name, ref: ref } }

          it_behaves_like 'creates a tag'
        end

        context 'when arguments are incorrect' do
          let(:tag_name) { '' }

          it_behaves_like 'a mutation that returns errors in the response', errors: ['Tag name invalid']
        end

        context 'when path is not correct' do
          let(:project_path) { 'unknown' }

          it_behaves_like 'a mutation that returns a top-level access error'
        end

        context 'when rate limited' do
          it_behaves_like 'rate limited endpoint', rate_limit_key: :tags_create, graphql: true do
            let_it_be(:other_project) { create(:project, :public, :small_repo, developers: current_user) }

            def request
              post_graphql_mutation(mutation, current_user: current_user)
            end

            def request_with_second_scope
              post_graphql_mutation(
                graphql_mutation(:tag_create, input.merge(project_path: other_project.full_path)),
                current_user: current_user
              )
            end
          end
        end

        context 'when the request is missing from the context', :clean_gitlab_redis_rate_limiting do
          # GraphqlChannel executes mutations without a Rack request.
          let(:context) { { current_user: current_user, is_sessionless_user: false } }

          it 'still applies the rate limit' do
            expect(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
              .with(:tags_create, scope: { project: project })
              .and_return(true)

            result = GitlabSchema.execute(mutation.query, context: context, variables: mutation.variables)

            expect(result.to_h['errors'].pluck('message'))
              .to include('This endpoint has been requested too many times. Try again later.')
          end
        end
      end
    end
  end
end
