# frozen_string_literal: true

RSpec.shared_examples 'issuable supports timelog creation mutation' do
  let(:mutation_response) { graphql_mutation_response(:timelog_create) }
  let(:spent_at) { '2022-11-16T12:59:35+0100' }
  let(:mutation) { graphql_mutation(:timelogCreate, variables) }

  let(:variables) do
    {
      'time_spent' => time_spent,
      'spent_at' => spent_at,
      'summary' => 'Test summary',
      'issuable_id' => issuable.to_global_id.to_s
    }
  end

  context 'when the user is anonymous' do
    before do
      post_graphql_mutation(mutation, current_user: current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user is a guest member of the namespace' do
    let(:current_user) { create(:user) }

    before do
      users_container.add_guest(current_user)

      post_graphql_mutation(mutation, current_user: current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to create a timelog' do
    let(:current_user) { author }

    before do
      users_container.add_reporter(current_user)
    end

    context 'with valid data' do
      it 'creates the timelog' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Timelog.count }.by(1)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['timelog']).to include(
          'timeSpent' => 3600,
          # This also checks that the ISO time was converted to UTC
          'spentAt' => '2022-11-16T11:59:35Z',
          'summary' => 'Test summary'
        )
      end
    end

    context 'when spent_at is not provided', time_travel_to: '2024-04-23 22:50:00 +0200' do
      let(:variables) do
        {
          'time_spent' => time_spent,
          'summary' => 'Test summary',
          'issuable_id' => issuable.to_global_id.to_s
        }
      end

      it 'creates the timelog using the current time' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Timelog.count }.by(1)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['timelog']).to include(
          'timeSpent' => 3600,
          'spentAt' => '2024-04-23T20:50:00Z',
          'summary' => 'Test summary'
        )
      end
    end

    context 'with invalid time_spent' do
      let(:time_spent) { '3h e' }

      it 'returns an error' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { Timelog.count }.by(0)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to match_array(
          ['Time spent must be formatted correctly. For example: 1h 30m.'])
        expect(mutation_response['timelog']).to be_nil
      end
    end
  end
end

RSpec.shared_examples 'issuable does not support timelog creation mutation' do
  let(:mutation_response) { graphql_mutation_response(:timelog_create) }
  let(:mutation) do
    variables = {
      'time_spent' => time_spent,
      'spent_at' => '2022-11-16T12:59:35+0100',
      'summary' => 'Test summary',
      'issuable_id' => issuable.to_global_id.to_s
    }
    graphql_mutation(:timelogCreate, variables)
  end

  context 'when the user is anonymous' do
    before do
      post_graphql_mutation(mutation, current_user: current_user)
    end

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when the user is a guest member of the namespace' do
    let(:current_user) { create(:user) }

    before do
      users_container.add_guest(current_user)

      post_graphql_mutation(mutation, current_user: current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { contain_exactly(include('is not a valid ID for')) }
    end
  end

  context 'when user has permissions to create a timelog' do
    let(:current_user) { author }

    before do
      users_container.add_reporter(current_user)
    end

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { contain_exactly(include('is not a valid ID for')) }
    end
  end
end
