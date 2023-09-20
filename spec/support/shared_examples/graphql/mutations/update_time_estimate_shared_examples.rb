# frozen_string_literal: true

RSpec.shared_examples 'updating time estimate' do
  context 'when setting time estimate', :aggregate_failures do
    using RSpec::Parameterized::TableSyntax

    let(:input_params) { input.merge(extra_params).merge({ timeEstimate: time_estimate }) }

    before do
      resource.update!(time_estimate: 1800)
    end

    context 'when time estimate is not provided' do
      let(:input_params) { input.merge(extra_params).except(:timeEstimate) }

      it 'does not update' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { resource.reload.time_estimate }
      end
    end

    context 'when time estimate is not a valid numerical value' do
      let(:time_estimate) { '-3.5d' }

      it 'does not update' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { resource.reload.time_estimate }
      end

      it 'returns error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including('message' => /must be greater than or equal to zero/))
      end
    end

    context 'when time estimate is not a number' do
      let(:time_estimate) { 'nonsense' }

      it 'does not update' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { resource.reload.time_estimate }
      end

      it 'returns error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to include(a_hash_including('message' => /must be formatted correctly/))
      end
    end

    context 'when time estimate is valid' do
      let(:time_estimate) { "1h" }

      before do
        post_graphql_mutation(mutation, current_user: current_user)
      end

      it_behaves_like 'a working GraphQL mutation'

      where(:time_estimate, :value) do
        '1h'              | 3600
        '0h'              | 0
        '-0h'             | 0
        nil               | 0
      end

      with_them do
        specify do
          expect(graphql_data_at(mutation_name, resource.class.to_s.underscore, 'timeEstimate')).to eq(value)
        end
      end
    end
  end
end
