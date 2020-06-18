# frozen_string_literal: true

require 'spec_helper'

describe 'getting user information' do
  include GraphqlHelpers

  let(:query) do
    graphql_query_for(:user, user_params, user_fields)
  end

  let(:user_fields) { all_graphql_fields_for('User', max_depth: 2) }

  context 'no parameters are provided' do
    let(:user_params) { nil }

    it 'mentions the missing required parameters' do
      post_graphql(query)

      expect_graphql_errors_to_include(/username/)
    end
  end

  context 'looking up a user by username' do
    let_it_be(:project_a) { create(:project, :repository) }
    let_it_be(:project_b) { create(:project, :repository) }
    let_it_be(:user, reload: true) { create(:user, developer_projects: [project_a, project_b]) }
    let_it_be(:authorised_user) { create(:user, developer_projects: [project_a, project_b]) }
    let_it_be(:unauthorized_user) { create(:user) }

    let_it_be(:assigned_mr) do
      create(:merge_request, :unique_branches,
             source_project: project_a, assignees: [user])
    end
    let_it_be(:assigned_mr_b) do
      create(:merge_request, :unique_branches,
             source_project: project_b, assignees: [user])
    end
    let_it_be(:assigned_mr_c) do
      create(:merge_request, :unique_branches,
             source_project: project_b, assignees: [user])
    end
    let_it_be(:authored_mr) do
      create(:merge_request, :unique_branches,
             source_project: project_a, author: user)
    end
    let_it_be(:authored_mr_b) do
      create(:merge_request, :unique_branches,
             source_project: project_b, author: user)
    end
    let_it_be(:authored_mr_c) do
      create(:merge_request, :unique_branches,
             source_project: project_b, author: user)
    end

    let(:current_user) { authorised_user }
    let(:authored_mrs) { graphql_data_at(:user, :authored_merge_requests, :nodes) }
    let(:assigned_mrs) { graphql_data_at(:user, :assigned_merge_requests, :nodes) }
    let(:user_params) { { username: user.username } }

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'the user is an active user' do
      it_behaves_like 'a working graphql query'

      it 'can access user profile fields' do
        presenter = UserPresenter.new(user)

        expect(graphql_data['user']).to match(
          a_hash_including(
            'id' => global_id_of(user),
            'state' => presenter.state,
            'name' => presenter.name,
            'username' => presenter.username,
            'webUrl' => presenter.web_url,
            'avatarUrl' => presenter.avatar_url
          ))
      end

      describe 'assignedMergeRequests' do
        let(:user_fields) do
          query_graphql_field(:assigned_merge_requests, mr_args, 'nodes { id }')
        end
        let(:mr_args) { nil }

        it_behaves_like 'a working graphql query'

        it 'can be found' do
          expect(assigned_mrs).to contain_exactly(
            a_hash_including('id' => global_id_of(assigned_mr)),
            a_hash_including('id' => global_id_of(assigned_mr_b)),
            a_hash_including('id' => global_id_of(assigned_mr_c))
          )
        end

        context 'applying filters' do
          context 'filtering by IID without specifying a project' do
            let(:mr_args) do
              { iids: [assigned_mr_b.iid.to_s] }
            end

            it 'return an argument error that mentions the missing fields' do
              expect_graphql_errors_to_include(/projectPath/)
            end
          end

          context 'filtering by project path and IID' do
            let(:mr_args) do
              { project_path: project_b.full_path, iids: [assigned_mr_b.iid.to_s] }
            end

            it 'selects the correct MRs' do
              expect(assigned_mrs).to contain_exactly(
                a_hash_including('id' => global_id_of(assigned_mr_b))
              )
            end
          end

          context 'filtering by project path' do
            let(:mr_args) do
              { project_path: project_b.full_path }
            end

            it 'selects the correct MRs' do
              expect(assigned_mrs).to contain_exactly(
                a_hash_including('id' => global_id_of(assigned_mr_b)),
                a_hash_including('id' => global_id_of(assigned_mr_c))
              )
            end
          end
        end

        context 'the current user does not have access' do
          let(:current_user) { unauthorized_user }

          it 'cannot be found' do
            expect(assigned_mrs).to be_empty
          end
        end
      end

      describe 'authoredMergeRequests' do
        let(:user_fields) do
          query_graphql_field(:authored_merge_requests, mr_args, 'nodes { id }')
        end
        let(:mr_args) { nil }

        it_behaves_like 'a working graphql query'

        it 'can be found' do
          expect(authored_mrs).to contain_exactly(
            a_hash_including('id' => global_id_of(authored_mr)),
            a_hash_including('id' => global_id_of(authored_mr_b)),
            a_hash_including('id' => global_id_of(authored_mr_c))
          )
        end

        context 'applying filters' do
          context 'filtering by IID without specifying a project' do
            let(:mr_args) do
              { iids: [authored_mr_b.iid.to_s] }
            end

            it 'return an argument error that mentions the missing fields' do
              expect_graphql_errors_to_include(/projectPath/)
            end
          end

          context 'filtering by project path and IID' do
            let(:mr_args) do
              { project_path: project_b.full_path, iids: [authored_mr_b.iid.to_s] }
            end

            it 'selects the correct MRs' do
              expect(authored_mrs).to contain_exactly(
                a_hash_including('id' => global_id_of(authored_mr_b))
              )
            end
          end

          context 'filtering by project path' do
            let(:mr_args) do
              { project_path: project_b.full_path }
            end

            it 'selects the correct MRs' do
              expect(authored_mrs).to contain_exactly(
                a_hash_including('id' => global_id_of(authored_mr_b)),
                a_hash_including('id' => global_id_of(authored_mr_c))
              )
            end
          end
        end

        context 'the current user does not have access' do
          let(:current_user) { unauthorized_user }

          it 'cannot be found' do
            expect(authored_mrs).to be_empty
          end
        end
      end
    end

    context 'the user is private' do
      before do
        user.update(private_profile: true)
        post_graphql(query, current_user: current_user)
      end

      context 'we only request basic fields' do
        let(:user_fields) { %i[id name username state web_url avatar_url] }

        it_behaves_like 'a working graphql query'
      end

      context 'we request the authoredMergeRequests' do
        let(:user_fields) { 'authoredMergeRequests { nodes { id } }' }

        it_behaves_like 'a working graphql query'

        it 'cannot be found' do
          expect(authored_mrs).to be_empty
        end

        context 'the current user is the user' do
          let(:current_user) { user }

          it 'can be found' do
            expect(authored_mrs).to include(
              a_hash_including('id' => global_id_of(authored_mr))
            )
          end
        end
      end

      context 'we request the assignedMergeRequests' do
        let(:user_fields) { 'assignedMergeRequests { nodes { id } }' }

        it_behaves_like 'a working graphql query'

        it 'cannot be found' do
          expect(assigned_mrs).to be_empty
        end

        context 'the current user is the user' do
          let(:current_user) { user }

          it 'can be found' do
            expect(assigned_mrs).to include(
              a_hash_including('id' => global_id_of(assigned_mr))
            )
          end
        end
      end
    end
  end
end
