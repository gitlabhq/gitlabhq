# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query', feature_category: :groups_and_projects do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let_it_be(:group_namespace) { create(:group, :private) }
  let_it_be(:public_group_namespace) { create(:group, :public) }
  let_it_be(:user_namespace) { create(:user_namespace, owner: user) }
  let_it_be(:project) { create(:project, group: group_namespace) }

  describe '.namespace' do
    subject { post_graphql(query, current_user: current_user) }

    let(:current_user) { user }

    let(:query) { graphql_query_for(:namespace, { 'fullPath' => target_namespace.full_path }, all_graphql_fields_for('Namespace')) }
    let(:query_result) { graphql_data['namespace'] }

    shared_examples 'retrieving a namespace' do
      context 'authorised query' do
        before do
          subject
        end

        it_behaves_like 'a working graphql query'

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'crossProjectPipelineAvailable' => target_namespace.licensed_feature_available?(:cross_project_pipeline),
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'unauthorised query' do
        before do
          subject
        end

        context 'anonymous user' do
          let(:current_user) { nil }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end

        context 'the current user does not have permission' do
          let(:current_user) { other_user }

          it 'does not retrieve the record' do
            expect(query_result).to be_nil
          end
        end
      end
    end

    context 'when achievements feature flag is off' do
      let(:target_namespace) { public_group_namespace }

      before do
        stub_feature_flags(achievements: false)
      end

      it 'does not return achievementsPath' do
        subject
        expect(query_result).to include(
          'achievementsPath' => nil
        )
      end
    end

    context 'when used with a public group' do
      let(:target_namespace) { public_group_namespace }
      let(:achievements_path) { ::Gitlab::Routing.url_helpers.group_achievements_path(target_namespace) }

      before do
        subject
      end

      it_behaves_like 'a working graphql query'

      context 'when user is a member' do
        before do
          public_group_namespace.add_developer(user)
        end

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'when user is anonymous' do
        let(:current_user) { nil }

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end

      context 'when user is not a member' do
        let(:current_user) { other_user }

        it 'fetches the expected data' do
          expect(query_result).to include(
            'fullPath' => target_namespace.full_path,
            'name' => target_namespace.name,
            'achievementsPath' => achievements_path
          )
        end
      end
    end

    context 'when used with a private namespace' do
      context 'retrieving a group' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { group_namespace }
          let(:achievements_path) { ::Gitlab::Routing.url_helpers.group_achievements_path(target_namespace) }

          before do
            group_namespace.add_developer(user)
          end
        end
      end

      context 'retrieving a user namespace' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { user_namespace }
          let(:achievements_path) { nil }
        end
      end

      context 'retrieving a project' do
        it_behaves_like 'retrieving a namespace' do
          let(:target_namespace) { project }
          let(:achievements_path) { nil }

          before do
            group_namespace.add_developer(user)
          end
        end
      end
    end

    describe 'linkPaths' do
      let_it_be(:test_project) { create(:project, :public) }
      let_it_be(:target_namespace) { test_project.project_namespace }

      let(:current_user) { user }

      describe 'newWorkItemEmailAddress' do
        let(:query_fields) do
          <<~QUERY
          linkPaths {
            ... on ProjectNamespaceLinks {
              newWorkItemEmailAddress
            }
          }
          QUERY
        end

        let(:query_string) { graphql_query_for(:namespace, { 'fullPath' => test_project.full_path }, query_fields) }

        context 'when work item creation via email is supported' do
          before do
            stub_incoming_email_setting(enabled: true, address: 'incoming+%{key}@localhost.com')
          end

          context 'when user has incoming email token' do
            before do
              user.ensure_incoming_email_token!
            end

            it 'returns the work item email address' do
              post_graphql(query_string, current_user: current_user)

              expected_address = "incoming+#{test_project.full_path_slug}-#{test_project.id}-" \
                "#{user.incoming_email_token}-issue@localhost.com"

              expect(graphql_dig_at(graphql_data, :namespace, :link_paths,
                :new_work_item_email_address)).to eq(expected_address)
            end
          end

          context 'when user does not have incoming email token' do
            before do
              user.update!(incoming_email_token: nil)
            end

            it 'generates and returns the work item email address' do
              post_graphql(query_string, current_user: current_user)

              expect(graphql_dig_at(graphql_data, :namespace, :link_paths,
                :new_work_item_email_address)).to be_present
              expect(user.reload.incoming_email_token).to be_present

              expected_address = "incoming+#{test_project.full_path_slug}-#{test_project.id}-" \
                "#{user.incoming_email_token}-issue@localhost.com"

              expect(graphql_dig_at(graphql_data, :namespace, :link_paths,
                :new_work_item_email_address)).to eq(expected_address)
            end
          end
        end

        context 'when work item creation via email is not supported' do
          before do
            stub_incoming_email_setting(enabled: false)
          end

          it 'returns nil' do
            post_graphql(query_string, current_user: current_user)

            expect(graphql_dig_at(graphql_data, :namespace, :link_paths, :new_work_item_email_address)).to be_nil
          end
        end

        context 'when user is nil' do
          let(:current_user) { nil }

          it 'returns nil' do
            post_graphql(query_string, current_user: current_user)

            expect(graphql_dig_at(graphql_data, :namespace, :link_paths, :new_work_item_email_address)).to be_nil
          end
        end
      end

      describe 'releasesPath, projectImportJiraPath, rssPath, calendarPath' do
        let(:query_fields) do
          <<~QUERY
          linkPaths {
            ... on ProjectNamespaceLinks {
              releasesPath
              projectImportJiraPath
              rssPath
              calendarPath
            }
          }
          QUERY
        end

        let(:query_string) { graphql_query_for(:namespace, { 'fullPath' => test_project.full_path }, query_fields) }

        it 'returns the project link paths' do
          post_graphql(query_string, current_user: current_user)

          link_paths = graphql_dig_at(graphql_data, :namespace, :link_paths)

          expect(link_paths).to include(
            'releasesPath' => ::Gitlab::Routing.url_helpers.project_releases_path(test_project),
            'projectImportJiraPath' => ::Gitlab::Routing.url_helpers.project_import_jira_path(test_project),
            'rssPath' => ::Gitlab::Routing.url_helpers.project_work_items_path(test_project, format: :atom),
            'calendarPath' => ::Gitlab::Routing.url_helpers.project_work_items_path(test_project, format: :ics)
          )
        end

        context 'when user is anonymous' do
          let(:current_user) { nil }

          it 'still returns the project link paths' do
            post_graphql(query_string, current_user: current_user)

            link_paths = graphql_dig_at(graphql_data, :namespace, :link_paths)

            expect(link_paths).to include(
              'releasesPath' => ::Gitlab::Routing.url_helpers.project_releases_path(test_project),
              'projectImportJiraPath' => ::Gitlab::Routing.url_helpers.project_import_jira_path(test_project),
              'rssPath' => ::Gitlab::Routing.url_helpers.project_work_items_path(test_project, format: :atom),
              'calendarPath' => ::Gitlab::Routing.url_helpers.project_work_items_path(test_project, format: :ics)
            )
          end
        end
      end

      describe 'group namespace link paths' do
        let_it_be(:test_group) { create(:group, :public) }
        let_it_be(:target_namespace) { test_group }

        let(:query_fields) do
          <<~QUERY
          linkPaths {
            ... on GroupNamespaceLinks {
              rssPath
              calendarPath
            }
          }
          QUERY
        end

        let(:query_string) { graphql_query_for(:namespace, { 'fullPath' => test_group.full_path }, query_fields) }

        it 'returns the group link paths' do
          post_graphql(query_string, current_user: current_user)

          link_paths = graphql_dig_at(graphql_data, :namespace, :link_paths)

          expect(link_paths).to include(
            'rssPath' => ::Gitlab::Routing.url_helpers.group_work_items_path(test_group, format: :atom),
            'calendarPath' => ::Gitlab::Routing.url_helpers.group_work_items_path(test_group, format: :ics)
          )
        end

        context 'when user is anonymous' do
          let(:current_user) { nil }

          it 'still returns the group link paths' do
            post_graphql(query_string, current_user: current_user)

            link_paths = graphql_dig_at(graphql_data, :namespace, :link_paths)

            expect(link_paths).to include(
              'rssPath' => ::Gitlab::Routing.url_helpers.group_work_items_path(test_group, format: :atom),
              'calendarPath' => ::Gitlab::Routing.url_helpers.group_work_items_path(test_group, format: :ics)
            )
          end
        end
      end
    end
  end
end
