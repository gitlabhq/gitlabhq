# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Querying a Milestone' do
  include GraphqlHelpers

  let_it_be(:guest) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:release_a) { create(:release, project: project) }
  let_it_be(:release_b) { create(:release, project: project) }

  before_all do
    milestone.releases << [release_a, release_b]
    project.add_guest(guest)
  end

  let(:expected_release_nodes) do
    contain_exactly(a_graphql_entity_for(release_a), a_graphql_entity_for(release_b))
  end

  context 'when we post the query' do
    let(:current_user) { nil }
    let(:query) do
      graphql_query_for('milestone', { id: milestone.to_global_id.to_s }, all_graphql_fields_for('Milestone'))
    end

    subject { graphql_data['milestone'] }

    before do
      post_graphql(query, current_user: current_user)
    end

    context 'when the user has access to the milestone' do
      let(:current_user) { guest }

      it_behaves_like 'a working graphql query'

      it { is_expected.to include('title' => milestone.name) }

      it 'contains release information' do
        is_expected.to include('releases' => include('nodes' => expected_release_nodes))
      end
    end

    context 'when the user does not have access to the milestone' do
      it_behaves_like 'a working graphql query'

      it { is_expected.to be_nil }
    end

    context 'when ID argument is missing' do
      let(:query) do
        graphql_query_for('milestone', {}, 'title')
      end

      it 'raises an exception' do
        expect(graphql_errors).to include(a_hash_including('message' => "Field 'milestone' is missing required arguments: id"))
      end
    end
  end

  context 'when there are two milestones' do
    let_it_be(:milestone_b) { create(:milestone, project: project) }

    let(:current_user) { guest }
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

    it 'produces correct results' do
      r = run_with_clean_state(multi_query,
                           context: { current_user: current_user },
                           variables: {
                             id_a: global_id_of(milestone).to_s,
                             id_b: milestone_b.to_global_id.to_s
                           })

      expect(r.to_h['errors']).to be_blank
      expect(graphql_dig_at(r.to_h, :data, :a, :releases, :nodes)).to match expected_release_nodes
      expect(graphql_dig_at(r.to_h, :data, :b, :releases, :nodes)).to be_empty
    end

    it 'does not suffer from N+1 performance issues' do
      baseline = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(single_query,
                             context: { current_user: current_user },
                             variables: { id_a: milestone.to_global_id.to_s })
      end

      multi = ActiveRecord::QueryRecorder.new do
        run_with_clean_state(multi_query,
                             context: { current_user: current_user },
                             variables: {
                               id_a: milestone.to_global_id.to_s,
                               id_b: milestone_b.to_global_id.to_s
                             })
      end

      expect(multi).not_to exceed_query_limit(baseline)
    end
  end
end
