# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting user information', feature_category: :user_management do
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
    let_it_be(:user, reload: true) { create(:user, developer_of: [project_a, project_b]) }
    let_it_be(:authorised_user) { create(:user, developer_of: [project_a, project_b]) }
    let_it_be(:unauthorized_user) { create(:user) }
    let_it_be(:admin) { create(:user, :admin) }

    let_it_be(:assigned_mr) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_a, assignees: [user])
    end

    let_it_be(:assigned_mr_b) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_b, assignees: [user])
    end

    let_it_be(:assigned_mr_c) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_b, assignees: [user])
    end

    let_it_be(:authored_mr) do
      create(:merge_request, :unique_branches, source_project: project_a, author: user)
    end

    let_it_be(:authored_mr_b) do
      create(:merge_request, :unique_branches, source_project: project_b, author: user)
    end

    let_it_be(:authored_mr_c) do
      create(:merge_request, :unique_branches, source_project: project_b, author: user)
    end

    let_it_be(:reviewed_mr) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_a, reviewers: [user])
    end

    let_it_be(:reviewed_mr_b) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_b, reviewers: [user])
    end

    let_it_be(:reviewed_mr_c) do
      create(:merge_request, :unique_branches, :unique_author, source_project: project_b, reviewers: [user])
    end

    let(:current_user) { authorised_user }
    let(:authored_mrs) { graphql_data_at(:user, :authored_merge_requests, :nodes) }
    let(:assigned_mrs) { graphql_data_at(:user, :assigned_merge_requests, :nodes) }
    let(:reviewed_mrs) { graphql_data_at(:user, :review_requested_merge_requests, :nodes) }
    let(:user_params) { { username: user.username } }

    before do
      create(:user_status, user: user)
      post_graphql(query, current_user: current_user)
    end

    context 'the user is an active user' do
      it_behaves_like 'a working graphql query'

      it 'can access user profile fields' do
        presenter = UserPresenter.new(user)

        expect(graphql_data['user']).to match(
          a_graphql_entity_for(
            user,
            :username,
            'state' => presenter.state,
            'name' => presenter.name,
            'webUrl' => presenter.web_url,
            'avatarUrl' => presenter.avatar_url,
            'email' => presenter.public_email,
            'publicEmail' => presenter.public_email
          ))

        expect(graphql_data['user']['status']).to match(
          a_hash_including(
            'emoji' => presenter.status.emoji,
            'message' => presenter.status.message,
            'availability' => presenter.status.availability.upcase
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
            a_graphql_entity_for(assigned_mr),
            a_graphql_entity_for(assigned_mr_b),
            a_graphql_entity_for(assigned_mr_c)
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
                a_graphql_entity_for(assigned_mr_b)
              )
            end
          end

          context 'filtering by project path' do
            let(:mr_args) do
              { project_path: project_b.full_path }
            end

            it 'selects the correct MRs' do
              expect(assigned_mrs).to contain_exactly(
                a_graphql_entity_for(assigned_mr_b),
                a_graphql_entity_for(assigned_mr_c)
              )
            end
          end

          context 'filtering by author' do
            let(:author) { assigned_mr_b.author }
            let(:mr_args) { { author_username: author.username } }

            it 'finds the authored mrs' do
              expect(assigned_mrs).to contain_exactly(
                a_graphql_entity_for(assigned_mr_b)
              )
            end
          end

          context 'filtering by reviewer' do
            let(:reviewer) { create(:user) }
            let(:mr_args) { { reviewer_username: reviewer.username } }

            it 'finds the assigned mrs' do
              assigned_mr_b.reviewers << reviewer
              assigned_mr_c.reviewers << reviewer

              post_graphql(query, current_user: current_user)

              expect(assigned_mrs).to contain_exactly(
                a_graphql_entity_for(assigned_mr_b),
                a_graphql_entity_for(assigned_mr_c)
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

      describe 'reviewRequestedMergeRequests' do
        let(:user_fields) do
          query_graphql_field(:review_requested_merge_requests, mr_args, 'nodes { id }')
        end

        let(:mr_args) { nil }

        it_behaves_like 'a working graphql query'

        it 'can be found' do
          expect(reviewed_mrs).to contain_exactly(
            a_graphql_entity_for(reviewed_mr),
            a_graphql_entity_for(reviewed_mr_b),
            a_graphql_entity_for(reviewed_mr_c)
          )
        end

        context 'applying filters' do
          context 'filtering by IID without specifying a project' do
            let(:mr_args) do
              { iids: [reviewed_mr_b.iid.to_s] }
            end

            it 'return an argument error that mentions the missing fields' do
              expect_graphql_errors_to_include(/projectPath/)
            end
          end

          context 'filtering by project path and IID' do
            let(:mr_args) do
              { project_path: project_b.full_path, iids: [reviewed_mr_b.iid.to_s] }
            end

            it 'selects the correct MRs' do
              expect(reviewed_mrs).to contain_exactly(
                a_graphql_entity_for(reviewed_mr_b)
              )
            end
          end

          context 'filtering by project path' do
            let(:mr_args) do
              { project_path: project_b.full_path }
            end

            it 'selects the correct MRs' do
              expect(reviewed_mrs).to contain_exactly(
                a_graphql_entity_for(reviewed_mr_b),
                a_graphql_entity_for(reviewed_mr_c)
              )
            end
          end

          context 'filtering by author' do
            let(:author) { reviewed_mr_b.author }
            let(:mr_args) { { author_username: author.username } }

            it 'finds the authored mrs' do
              expect(reviewed_mrs).to contain_exactly(
                a_graphql_entity_for(reviewed_mr_b)
              )
            end
          end

          context 'filtering by assignee' do
            let(:assignee) { create(:user) }
            let(:mr_args) { { assignee_username: assignee.username } }

            it 'finds the authored mrs' do
              reviewed_mr_c.assignees << assignee

              post_graphql(query, current_user: current_user)

              expect(reviewed_mrs).to contain_exactly(
                a_graphql_entity_for(reviewed_mr_c)
              )
            end
          end
        end

        context 'the current user does not have access' do
          let(:current_user) { unauthorized_user }

          it 'cannot be found' do
            expect(reviewed_mrs).to be_empty
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
            a_graphql_entity_for(authored_mr),
            a_graphql_entity_for(authored_mr_b),
            a_graphql_entity_for(authored_mr_c)
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

          context 'filtering by assignee' do
            let(:assignee) { create(:user) }
            let(:mr_args) { { assignee_username: assignee.username } }

            it 'finds the assigned mrs' do
              authored_mr.assignees << assignee
              authored_mr_c.assignees << assignee

              post_graphql(query, current_user: current_user)

              expect(authored_mrs).to contain_exactly(
                a_graphql_entity_for(authored_mr),
                a_graphql_entity_for(authored_mr_c)
              )
            end
          end

          context 'filtering by reviewer' do
            let(:reviewer) { create(:user) }
            let(:mr_args) { { reviewer_username: reviewer.username } }

            it 'finds the assigned mrs' do
              authored_mr_b.reviewers << reviewer
              authored_mr_c.reviewers << reviewer

              post_graphql(query, current_user: current_user)

              expect(authored_mrs).to contain_exactly(
                a_graphql_entity_for(authored_mr_b),
                a_graphql_entity_for(authored_mr_c)
              )
            end
          end

          context 'filtering by project path and IID' do
            let(:mr_args) do
              { project_path: project_b.full_path, iids: [authored_mr_b.iid.to_s] }
            end

            it 'selects the correct MRs' do
              expect(authored_mrs).to contain_exactly(
                a_graphql_entity_for(authored_mr_b)
              )
            end
          end

          context 'filtering by project path' do
            let(:mr_args) do
              { project_path: project_b.full_path }
            end

            it 'selects the correct MRs' do
              expect(authored_mrs).to contain_exactly(
                a_graphql_entity_for(authored_mr_b),
                a_graphql_entity_for(authored_mr_c)
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
        user.update!(private_profile: true)
        post_graphql(query, current_user: current_user)
      end

      context 'we only request basic fields' do
        let(:user_fields) { %i[id name username state web_url avatar_url] }

        it_behaves_like 'a working graphql query'
      end

      context 'we request the groupMemberships' do
        let_it_be(:membership_a) { create(:group_member, user: user) }

        let(:group_memberships) { graphql_data_at(:user, :group_memberships, :nodes) }
        let(:user_fields) { 'groupMemberships { nodes { id } }' }

        it_behaves_like 'a working graphql query'

        it 'cannot be found' do
          expect(group_memberships).to be_empty
        end

        context 'the current user is the user' do
          let(:current_user) { user }

          it 'can be found' do
            expect(group_memberships).to include(
              a_graphql_entity_for(membership_a)
            )
          end
        end
      end

      context 'we request the projectMemberships' do
        let_it_be(:membership_a) { create(:project_member, user: user) }

        let(:project_memberships) { graphql_data_at(:user, :project_memberships, :nodes) }
        let(:user_fields) { 'projectMemberships { nodes { id } }' }

        it_behaves_like 'a working graphql query'

        it 'cannot be found' do
          expect(project_memberships).to be_empty
        end

        context 'the current user is the user' do
          let(:current_user) { user }

          it 'can be found' do
            expect(project_memberships).to include(
              a_graphql_entity_for(membership_a)
            )
          end
        end
      end

      context 'when requesting the projectCount' do
        let(:project_count) { graphql_data_at(:user, :project_count) }
        let(:user_fields) { 'projectCount' }

        it_behaves_like 'a working graphql query'

        context 'when the current user is unauthorized' do
          let(:current_user) { unauthorized_user }

          it 'returns nil' do
            expect(project_count).to be_nil
          end
        end

        context 'when the current user is the user' do
          let(:current_user) { user }

          it 'returns the count' do
            expect(project_count).to eq(2)
          end
        end

        context 'when the current user is an admin' do
          let(:current_user) { admin }

          it 'returns the count' do
            expect(project_count).to eq(2)
          end
        end
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
              a_graphql_entity_for(authored_mr)
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
            expect(assigned_mrs).to contain_exactly(
              a_graphql_entity_for(assigned_mr),
              a_graphql_entity_for(assigned_mr_b),
              a_graphql_entity_for(assigned_mr_c)
            )
          end
        end
      end
    end

    context 'the user is project bot' do
      let(:user) { create(:user, :project_bot) }

      before do
        post_graphql(query, current_user: current_user)
      end

      context 'we only request basic fields' do
        let(:user_fields) { %i[id name username state web_url avatar_url] }

        it_behaves_like 'a working graphql query'
      end
    end
  end

  context 'authored merge requests' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:merge_request1) do
      create(:merge_request, source_project: project, source_branch: '1', author: current_user)
    end

    let_it_be(:merge_request2) do
      create(:merge_request, source_project: project, source_branch: '2', author: current_user)
    end

    let_it_be(:merge_request_different_user) do
      create(:merge_request, source_project: project, source_branch: '3', author: create(:user))
    end

    let_it_be(:merge_request_different_group) do
      create(:merge_request, source_project: create(:project, :public), author: current_user)
    end

    let_it_be(:merge_request_subgroup) do
      create(:merge_request, source_project: create(:project, :public, group: subgroup), author: current_user)
    end

    let(:query) do
      %(
        query {
          currentUser {
            authoredMergeRequests(groupId: "#{group.to_global_id}") {
              nodes {
                id
              }
            }
          }
        }
      )
    end

    it 'returns merge requests for the current user for the specified group' do
      post_graphql(query, current_user: current_user)

      expect(graphql_data_at(:current_user, :authored_merge_requests, :nodes).pluck('id')).to contain_exactly(
        merge_request1.to_global_id.to_s, merge_request2.to_global_id.to_s, merge_request_subgroup.to_global_id.to_s)
    end
  end
end
