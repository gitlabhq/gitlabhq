# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:current_user) { create_default(:user, :admin) }

  def create_ci_runner(version:, revision: nil, ip_address: nil, **args)
    runner_manager_args = { version: version, revision: revision, ip_address: ip_address }.compact

    create(:ci_runner, **args).tap do |runner|
      create(:ci_runner_machine, runner: runner, **runner_manager_args)
    end
  end

  describe 'Query.runners', :freeze_time do
    before_all do
      freeze_time # Freeze time before `let_it_be` runs, so that runner statuses are frozen during execution
    end

    after :all do
      unfreeze_time
    end

    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance, :almost_offline, description: 'Instance runner') }
    let_it_be(:instance_runner_manager) do
      create(:ci_runner_machine, runner: instance_runner, version: 'abc', revision: '123', ip_address: '127.0.0.1')
    end

    let_it_be(:project_runner) { create(:ci_runner, :project, :paused, description: 'Project runner', projects: [project]) }
    let_it_be(:project_runner_manager) do
      create(:ci_runner_machine, runner: project_runner, version: 'def', revision: '456', ip_address: '127.0.0.1')
    end

    let(:runners_graphql_data) { graphql_data_at(:runners) }

    let(:params) { {} }

    let(:fields) do
      <<~QUERY
        nodes {
          #{all_graphql_fields_for('CiRunner', excluded: excluded_fields)}
        }
      QUERY
    end

    let(:query) do
      %(
         query {
           runners {
             #{fields}
           }
         }
       )
    end

    # Exclude fields from deeper objects which are problematic:
    # - ownerProject.pipeline: Needs arguments (iid or sha)
    # - project.productAnalyticsState: Can be requested only for 1 Project(s) at a time.
    # - mergeTrains Licensed feature
    let(:excluded_fields) { %w[pipeline productAnalyticsState mergeTrains] }

    it 'returns expected runners' do
      post_graphql(query, current_user: current_user)

      expect(runners_graphql_data['nodes']).to match_array(
        Ci::Runner.all.map { |expected_runner| a_graphql_entity_for(expected_runner) }
      )
    end

    context 'with filters' do
      let_it_be(:admin) { create(:admin) }
      let_it_be(:user) { create(:user) }

      shared_examples 'a working graphql query returning expected runners' do
        it_behaves_like 'a working graphql query' do
          before do
            post_graphql(query, current_user: current_user)
          end
        end

        it 'returns expected runners' do
          post_graphql(query, current_user: current_user)

          expect(runners_graphql_data['nodes']).to match_array(
            Array(expected_runners).map { |expected_runner| a_graphql_entity_for(expected_runner) }
          )
        end
      end

      context 'when filtered on type and status' do
        let(:query) do
          %(
            query {
              runners(type: #{runner_type}, status: #{status}) {
                #{fields}
              }
            }
          )
        end

        before do
          allow_next_instance_of(::Gitlab::Ci::RunnerUpgradeCheck) do |instance|
            allow(instance).to receive(:check_runner_upgrade_suggestion)
          end
        end

        context 'runner_type is INSTANCE_TYPE and status is ONLINE' do
          let(:runner_type) { 'INSTANCE_TYPE' }
          let(:status) { 'ONLINE' }

          let(:expected_runners) { instance_runner }

          it_behaves_like 'a working graphql query returning expected runners'
        end

        context 'runner_type is PROJECT_TYPE and status is NEVER_CONTACTED' do
          let(:runner_type) { 'PROJECT_TYPE' }
          let(:status) { 'NEVER_CONTACTED' }

          let(:expected_runners) { project_runner }

          it_behaves_like 'a working graphql query returning expected runners'
        end
      end

      context 'when filtered on version prefix' do
        let_it_be(:runner_15_10_1) { create_ci_runner(version: '15.10.1') }

        let_it_be(:runner_15_11_0) { create_ci_runner(version: '15.11.0') }
        let_it_be(:runner_15_11_1) { create_ci_runner(version: '15.11.1') }

        let_it_be(:runner_16_1_0) { create_ci_runner(version: '16.1.0') }

        let(:fields) do
          <<~QUERY
            nodes {
              id
            }
          QUERY
        end

        let(:query) do
          %(
            query {
              runners(versionPrefix: "#{version_prefix}") {
                #{fields}
              }
            }
          )
        end

        context 'when version_prefix is "15."' do
          let(:version_prefix) { '15.' }

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) { [runner_15_10_1, runner_15_11_0, runner_15_11_1] }
          end
        end

        context 'when version_prefix is "15.11."' do
          let(:version_prefix) { '15.11.' }

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) { [runner_15_11_0, runner_15_11_1] }
          end
        end

        context 'when version_prefix is "15.11.0"' do
          let(:version_prefix) { '15.11.0' }

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) { runner_15_11_0 }
          end
        end

        context 'when version_prefix is not digits' do
          let(:version_prefix) { 'a.b' }

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) do
              [instance_runner, project_runner, runner_15_10_1, runner_15_11_0, runner_15_11_1, runner_16_1_0]
            end
          end
        end
      end

      context 'when filtered by creator' do
        let_it_be(:runner_created_by_user) { create(:ci_runner, creator: user) }

        let(:query) do
          %(
            query {
              runners(creatorId: "#{creator.to_global_id}") {
                #{fields}
              }
            }
          )
        end

        context 'when existing user id given' do
          let(:creator) { user }

          before do
            create(:ci_runner, creator: create(:user)) # Should not be returned
          end

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) { runner_created_by_user }
          end
        end

        context 'when non existent user id given' do
          let(:creator) { User.new(id: non_existing_record_id) }

          it 'does not return any runners' do
            post_graphql(query, current_user: current_user)

            expect(graphql_data_at(:runners, :nodes)).to be_empty
          end
        end
      end

      context 'when filtered by owner' do
        let_it_be(:runner_created_by_user) { create(:ci_runner, creator: user) }
        let_it_be(:runner_created_by_admin) { create(:ci_runner, creator: admin) }
        let_it_be(:project) { create(:project, :in_group) }
        let_it_be(:group) { project.parent }
        let_it_be(:project_runner) { create(:ci_runner, :project, projects: [project], creator: user) }
        let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], creator: admin) }

        context 'when filtered by ownerWildcard' do
          let(:query) do
            %(
              query {
                runners(ownerWildcard: ADMINISTRATORS) {
                  #{fields}
                }
              }
            )
          end

          it_behaves_like 'a working graphql query returning expected runners' do
            let(:expected_runners) { runner_created_by_admin }
          end
        end

        context 'when filtered by ownerFullPath' do
          let(:query) do
            %(
              query {
                runners(ownerFullPath: "#{owner_full_path}") {
                  #{fields}
                }
              }
            )
          end

          context 'when ownerFullPath refers to group' do
            let(:owner_full_path) { group.full_path }

            it_behaves_like 'a working graphql query returning expected runners' do
              let(:expected_runners) { group_runner }
            end
          end

          context 'when ownerFullPath refers to project' do
            let(:owner_full_path) { project.full_path }

            it_behaves_like 'a working graphql query returning expected runners' do
              let(:expected_runners) { project_runner }
            end
          end

          context 'when ownerFullPath is invalid' do
            let(:owner_full_path) { 'invalid' }

            it_behaves_like 'a working graphql query returning expected runners' do
              let(:expected_runners) { [] }
            end
          end
        end

        context 'when filtered by both ownerWildcard and ownerFullPath' do
          let(:query) do
            %(
              query {
                runners(ownerWildcard: ADMINISTRATORS, ownerFullPath: "some-path") {
                  #{fields}
                }
              }
            )
          end

          it 'returns error' do
            post_graphql(query, current_user: current_user)

            expect_graphql_errors_to_include('The ownerFullPath and ownerWildcardPath arguments are mutually exclusive.')
          end
        end
      end
    end
  end

  describe 'Runner query limits' do
    let_it_be(:user) { create(:user, :admin) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:user3) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
    let_it_be(:tag_list) { %w[n_plus_1_test some_tag] }
    let_it_be(:args) do
      { current_user: user, token: { personal_access_token: create(:personal_access_token, user: user) } }
    end

    let_it_be(:runner1) { create(:ci_runner, tag_list: tag_list, creator: user) }
    let_it_be(:runner2) do
      create(:ci_runner, :group, groups: [group], tag_list: tag_list, creator: user)
    end

    let_it_be(:runner3) do
      create(:ci_runner, :project, projects: [project], tag_list: tag_list, creator: user)
    end

    let(:runner_fragment) do
      <<~QUERY
        #{all_graphql_fields_for('CiRunner', excluded: excluded_fields)}
        createdBy {
          id
          username
          webPath
          webUrl
        }
      QUERY
    end

    # Exclude fields that are already hardcoded above (or tested separately),
    #   and also some fields from deeper objects which are problematic:
    # - createdBy: Known N+1 issues, but only on exotic fields which we don't normally use
    # - ownerProject.pipeline: Needs arguments (iid or sha)
    # - project.productAnalyticsState: Can be requested only for 1 Project(s) at a time.
    let(:excluded_fields) { %w[createdBy jobs pipeline productAnalyticsState] }

    let(:runners_query) do
      <<~QUERY
        {
          runners {
            nodes { #{runner_fragment} }
          }
        }
      QUERY
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      personal_access_token = create(:personal_access_token, user: user)
      args = { current_user: user, token: { personal_access_token: personal_access_token } }

      runners_control = ActiveRecord::QueryRecorder.new(skip_cached: false) { post_graphql(runners_query, **args) }

      setup_additional_records

      expect { post_graphql(runners_query, **args) }.not_to exceed_query_limit(runners_control)
    end

    def setup_additional_records
      # Add more runners (including owned by other users)
      runner4 = create(:ci_runner, tag_list: tag_list + %w[tag1 tag2], creator: user2)
      runner5 = create(:ci_runner, :group, groups: [create(:group)], tag_list: tag_list + %w[tag2 tag3], creator: user3)
      # Add one more project to runner
      runner3.assign_to(create(:project))

      # Add more runner managers (including to existing runners)
      runner_manager1 = create(:ci_runner_machine, runner: runner1)
      create(:ci_runner_machine, runner: runner1)
      create(:ci_runner_machine, runner: runner2, system_xid: runner_manager1.system_xid)
      create(:ci_runner_machine, runner: runner3)
      create(:ci_runner_machine, runner: runner4, version: '16.4.1')
      create(:ci_runner_machine, runner: runner5, version: '16.4.0', system_xid: runner_manager1.system_xid)
      create(:ci_runner_machine, runner: runner3)

      create(:ci_build, :failed, runner: runner4)
      create(:ci_build, :failed, runner: runner5)

      [runner4, runner5]
    end
  end

  describe 'pagination' do
    let(:data_path) { [:runners] }

    def pagination_query(params)
      graphql_query_for(:runners, params, "#{page_info} nodes { id }")
    end

    def pagination_results_data(runners)
      runners.map { |runner| GitlabSchema.parse_gid(runner['id'], expected_type: ::Ci::Runner).model_id.to_i }
    end

    let_it_be(:runners) do
      common_args = {
        version: 'abc',
        revision: '123',
        ip_address: '127.0.0.1'
      }

      [
        create_ci_runner(created_at: 4.days.ago, contacted_at: 3.days.ago, **common_args),
        create_ci_runner(created_at: 30.hours.ago, contacted_at: 1.day.ago, **common_args),
        create_ci_runner(created_at: 1.day.ago, contacted_at: 1.hour.ago, **common_args),
        create_ci_runner(created_at: 2.days.ago, contacted_at: 2.days.ago, **common_args),
        create_ci_runner(created_at: 3.days.ago, contacted_at: 1.second.ago, **common_args)
      ]
    end

    context 'when sorted by contacted_at ascending' do
      let(:ordered_runners) { runners.sort_by(&:contacted_at) }

      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :CONTACTED_ASC }
        let(:first_param) { 2 }
        let(:all_records) { ordered_runners.map(&:id) }
      end
    end

    context 'when sorted by created_at' do
      let(:ordered_runners) { runners.sort_by(&:created_at).reverse }

      it_behaves_like 'sorted paginated query' do
        let(:sort_param) { :CREATED_DESC }
        let(:first_param) { 2 }
        let(:all_records) { ordered_runners.map(&:id) }
      end
    end
  end
end

RSpec.describe 'Group.runners', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:group_owner) { create_default(:user, owner_of: group) }

  describe 'edges' do
    let_it_be(:runner) { create(:ci_runner, :group, :paused, description: 'Project runner', groups: [group]) }

    let(:query) do
      %(
        query($path: ID!) {
          group(fullPath: $path) {
            runners {
              edges {
                webUrl
                editUrl
                node { #{all_graphql_fields_for('CiRunner')} }
              }
            }
          }
        }
      )
    end

    it 'contains custom edge information' do
      r = GitlabSchema.execute(query, context: { current_user: group_owner }, variables: { path: group.full_path })

      edges = graphql_dig_at(r.to_h, :data, :group, :runners, :edges)

      expect(edges).to contain_exactly(a_graphql_entity_for(web_url: be_present, edit_url: be_present))
    end
  end
end
