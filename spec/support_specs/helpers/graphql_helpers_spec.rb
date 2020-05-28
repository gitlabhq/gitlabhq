# frozen_string_literal: true

require 'spec_helper'

describe GraphqlHelpers do
  include GraphqlHelpers

  describe '.graphql_mutation' do
    shared_examples 'correct mutation definition' do
      it 'returns correct mutation definition' do
        query = <<~MUTATION
          mutation($updateAlertStatusInput: UpdateAlertStatusInput!) {
            updateAlertStatus(input: $updateAlertStatusInput) {
              clientMutationId
            }
          }
        MUTATION
        variables = %q({"updateAlertStatusInput":{"projectPath":"test/project"}})

        is_expected.to eq(GraphqlHelpers::MutationDefinition.new(query, variables))
      end
    end

    context 'when fields argument is passed' do
      subject do
        graphql_mutation(:update_alert_status, { project_path: 'test/project' }, 'clientMutationId')
      end

      it_behaves_like 'correct mutation definition'
    end

    context 'when block is passed' do
      subject do
        graphql_mutation(:update_alert_status, { project_path: 'test/project' }) do
          'clientMutationId'
        end
      end

      it_behaves_like 'correct mutation definition'
    end

    context 'when both fields and a block are passed' do
      subject do
        graphql_mutation(:mutation_name, { variable_name: 'variable/value' }, 'fieldName') do
          'fieldName'
        end
      end

      it 'raises an ArgumentError' do
        expect { subject }.to raise_error(
          ArgumentError,
          'Please pass either `fields` parameter or a block to `#graphql_mutation`, but not both.'
        )
      end
    end
  end
end
