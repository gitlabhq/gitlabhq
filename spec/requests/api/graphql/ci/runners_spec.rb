# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners', feature_category: :fleet_visibility do
  include GraphqlHelpers

  let_it_be(:current_user) { create_default(:user, :admin) }

  describe 'Query.runners' do
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:instance_runner) { create(:ci_runner, :instance, version: 'abc', revision: '123', description: 'Instance runner', ip_address: '127.0.0.1') }
    let_it_be(:project_runner) { create(:ci_runner, :project, active: false, version: 'def', revision: '456', description: 'Project runner', projects: [project], ip_address: '127.0.0.1') }

    let(:runners_graphql_data) { graphql_data_at(:runners) }

    let(:params) { {} }

    let(:fields) do
      <<~QUERY
        nodes {
          #{all_graphql_fields_for('CiRunner', excluded: %w[createdBy ownerProject])}
          createdBy {
            username
            webPath
            webUrl
          }
          ownerProject {
            id
            path
            fullPath
            webUrl
          }
        }
      QUERY
    end

    context 'with filters' do
      shared_examples 'a working graphql query returning expected runners' do
        it_behaves_like 'a working graphql query' do
          before do
            post_graphql(query, current_user: current_user)
          end
        end

        it 'returns expected runners' do
          post_graphql(query, current_user: current_user)

          expect(runners_graphql_data['nodes']).to contain_exactly(
            *Array(expected_runners).map { |expected_runner| a_graphql_entity_for(expected_runner) }
          )
        end

        it 'does not execute more queries per runner', :aggregate_failures do
          # warm-up license cache and so on:
          personal_access_token = create(:personal_access_token, user: current_user)
          args = { current_user: current_user, token: { personal_access_token: personal_access_token } }
          post_graphql(query, **args)
          expect(graphql_data_at(:runners, :nodes)).not_to be_empty

          admin2 = create(:admin)
          personal_access_token = create(:personal_access_token, user: admin2)
          args = { current_user: admin2, token: { personal_access_token: personal_access_token } }
          control = ActiveRecord::QueryRecorder.new { post_graphql(query, **args) }

          runner2 = create(:ci_runner, :instance, version: '14.0.0', tag_list: %w[tag5 tag6], creator: admin2)
          runner3 = create(:ci_runner, :project, version: '14.0.1', projects: [project], tag_list: %w[tag3 tag8],
            creator: current_user)

          create(:ci_build, :failed, runner: runner2)
          create(:ci_runner_machine, runner: runner2, version: '16.4.1')

          create(:ci_build, :failed, runner: runner3)
          create(:ci_runner_machine, runner: runner3, version: '16.4.0')

          expect { post_graphql(query, **args) }.not_to exceed_query_limit(control)
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

        context 'runner_type is INSTANCE_TYPE and status is ACTIVE' do
          let(:runner_type) { 'INSTANCE_TYPE' }
          let(:status) { 'ACTIVE' }

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

        def create_ci_runner(args = {}, version:)
          create(:ci_runner, :project, **args).tap do |runner|
            create(:ci_runner_machine, runner: runner, version: version)
          end
        end
      end
    end

    context 'without filters' do
      context 'with managers requested for multiple runners' do
        let(:fields) do
          <<~QUERY
            nodes {
              managers {
                nodes {
                  #{all_graphql_fields_for('CiRunnerManager', max_depth: 1)}
                }
              }
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

        it 'does not execute more queries per runner', :aggregate_failures do
          # warm-up license cache and so on:
          personal_access_token = create(:personal_access_token, user: current_user)
          args = { current_user: current_user, token: { personal_access_token: personal_access_token } }
          post_graphql(query, **args)
          expect(graphql_data_at(:runners, :nodes)).not_to be_empty

          admin2 = create(:admin)
          personal_access_token = create(:personal_access_token, user: admin2)
          args = { current_user: admin2, token: { personal_access_token: personal_access_token } }
          control = ActiveRecord::QueryRecorder.new { post_graphql(query, **args) }

          create(:ci_runner, :instance, :with_runner_manager, version: '14.0.0', tag_list: %w[tag5 tag6],
            creator: admin2)
          create(:ci_runner, :project, :with_runner_manager, version: '14.0.1', projects: [project],
            tag_list: %w[tag3 tag8],
            creator: current_user)

          expect { post_graphql(query, **args) }.not_to exceed_query_limit(control)
        end
      end
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
        create(:ci_runner, :instance, created_at: 4.days.ago, contacted_at: 3.days.ago, **common_args),
        create(:ci_runner, :instance, created_at: 30.hours.ago, contacted_at: 1.day.ago, **common_args),
        create(:ci_runner, :instance, created_at: 1.day.ago, contacted_at: 1.hour.ago, **common_args),
        create(:ci_runner, :instance, created_at: 2.days.ago, contacted_at: 2.days.ago, **common_args),
        create(:ci_runner, :instance, created_at: 3.days.ago, contacted_at: 1.second.ago, **common_args)
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

RSpec.describe 'Group.runners' do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:group_owner) { create_default(:user) }

  before do
    group.add_owner(group_owner)
  end

  describe 'edges' do
    let_it_be(:runner) do
      create(:ci_runner, :group,
        active: false,
        version: 'def',
        revision: '456',
        description: 'Project runner',
        groups: [group],
        ip_address: '127.0.0.1')
    end

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
      r = GitlabSchema.execute(query,
                               context: { current_user: group_owner },
                               variables: { path: group.full_path })

      edges = graphql_dig_at(r.to_h, :data, :group, :runners, :edges)

      expect(edges).to contain_exactly(a_graphql_entity_for(web_url: be_present, edit_url: be_present))
    end
  end
end
