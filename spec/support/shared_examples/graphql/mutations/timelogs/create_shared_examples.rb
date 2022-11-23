# frozen_string_literal: true

RSpec.shared_examples 'issuable supports timelog creation mutation' do
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
          'spentAt' => '2022-07-08T00:00:00Z',
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
        expect(mutation_response['errors']).to match_array(['Time spent can\'t be blank'])
        expect(mutation_response['timelog']).to be_nil
      end
    end
  end
end

RSpec.shared_examples 'issuable does not support timelog creation mutation' do
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
