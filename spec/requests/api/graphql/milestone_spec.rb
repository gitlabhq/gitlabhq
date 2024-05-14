# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying a Milestone', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:inherited_guest) { create(:user) }
  let_it_be(:inherited_reporter) { create(:user) }
  let_it_be(:inherited_developer) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:release_a) { create(:release, project: project) }
  let_it_be(:release_b) { create(:release, project: project) }

  before_all do
    milestone.releases << [release_a, release_b]
    project.add_guest(guest)
    group.add_guest(inherited_guest)
    group.add_reporter(inherited_reporter)
    group.add_developer(inherited_developer)
  end

  let(:expected_release_nodes) do
    contain_exactly(a_graphql_entity_for(release_a), a_graphql_entity_for(release_b))
  end

  shared_examples 'returns the milestone successfully' do
    it_behaves_like 'a working graphql query'

    it { is_expected.to include('title' => milestone.name) }

    it 'contains release information' do
      is_expected.to include('releases' => include('nodes' => expected_release_nodes))
    end
  end

  context 'when we post the query' do
    context 'and the project is private' do
      let(:query) do
        graphql_query_for(
          'milestone',
          { id: milestone.to_global_id.to_s },
          all_graphql_fields_for('Milestone', excluded: %w[project group])
        )
      end

      subject { graphql_data['milestone'] }

      before do
        post_graphql(query, current_user: current_user)
      end

      context 'when the user is a direct project member' do
        context 'and the user is a guest' do
          let(:current_user) { guest }

          it_behaves_like 'returns the milestone successfully'

          context 'when milestone has no dates' do
            it 'returns upcoming and expired as false' do
              expect(graphql_data_at(:milestone, :due_date)).to be_nil
              expect(graphql_data_at(:milestone, :start_date)).to be_nil
              expect(graphql_data_at(:milestone, :upcoming)).to be false
              expect(graphql_data_at(:milestone, :expired)).to be false
            end
          end

          context 'when there are two milestones' do
            let_it_be(:milestone_b) { create(:milestone, project: project) }

            let(:milestone_fields) do
              <<~GQL
              fragment milestoneFields on Milestone {
                #{all_graphql_fields_for('Milestone', max_depth: 1)}
                releases { nodes { #{all_graphql_fields_for('Release', max_depth: 1)} } }
              }
              GQL
            end

            let(:single_query) do
              <<~GQL
              query ($id_a: MilestoneID!) {
                a: milestone(id: $id_a) { ...milestoneFields }
              }

              #{milestone_fields}
              GQL
            end

            let(:multi_query) do
              <<~GQL
              query ($id_a: MilestoneID!, $id_b: MilestoneID!) {
                a: milestone(id: $id_a) { ...milestoneFields }
                b: milestone(id: $id_b) { ...milestoneFields }
              }
              #{milestone_fields}
              GQL
            end

            it 'returns the correct releases associated with each milestone' do
              r = run_with_clean_state(
                multi_query,
                context: { current_user: current_user },
                variables: {
                  id_a: global_id_of(milestone).to_s,
                  id_b: milestone_b.to_global_id.to_s
                }
              )

              expect(r.to_h['errors']).to be_blank
              expect(graphql_dig_at(r.to_h, :data, :a, :releases, :nodes)).to match expected_release_nodes
              expect(graphql_dig_at(r.to_h, :data, :b, :releases, :nodes)).to be_empty
            end

            it 'does not suffer from N+1 performance issues' do
              baseline = ActiveRecord::QueryRecorder.new do
                run_with_clean_state(
                  single_query,
                  context: { current_user: current_user },
                  variables: { id_a: milestone.to_global_id.to_s }
                )
              end

              multi = ActiveRecord::QueryRecorder.new do
                run_with_clean_state(
                  multi_query,
                  context: { current_user: current_user },
                  variables: {
                    id_a: milestone.to_global_id.to_s,
                    id_b: milestone_b.to_global_id.to_s
                  }
                )
              end

              expect(multi).not_to exceed_query_limit(baseline)
            end
          end
        end
      end

      context 'when the user is an inherited member from the group' do
        where(:user) { [ref(:inherited_guest), ref(:inherited_reporter), ref(:inherited_developer)] }

        with_them do
          let(:current_user) { user }

          it_behaves_like 'returns the milestone successfully'
        end
      end

      context 'when unauthenticated' do
        let(:current_user) { nil }

        it_behaves_like 'a working graphql query'

        it { is_expected.to be_nil }

        context 'when ID argument is missing' do
          let(:query) do
            graphql_query_for('milestone', {}, 'title')
          end

          it 'raises an exception' do
            expect(graphql_errors).to include(a_hash_including('message' => "Field 'milestone' is missing required arguments: id"))
          end
        end
      end
    end
  end

  context 'for common GraphQL/REST' do
    it_behaves_like 'group milestones including ancestors and descendants'

    def query_group_milestone_ids(params)
      query = graphql_query_for('group', { 'fullPath' => group.full_path },
        query_graphql_field('milestones', params, query_graphql_path([:nodes], :id))
      )

      post_graphql(query, current_user: current_user)

      graphql_data_at(:group, :milestones, :nodes).pluck('id').map { |gid| GlobalID.parse(gid).model_id.to_i }
    end
  end
end
