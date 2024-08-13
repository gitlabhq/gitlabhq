# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'an assignable resource' do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }

  subject(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  describe '#resolve' do
    let_it_be(:assignee) { create(:user) }
    let_it_be(:assignee2) { create(:user) }

    let(:assignee_usernames) { [assignee.username] }
    let(:mutated_resource) { subject[resource.class.name.underscore.to_sym] }
    let(:mode) { described_class.arguments['operationMode'].default_value }

    subject do
      mutation.resolve(
        project_path: resource.project.full_path,
        iid: resource.iid,
        operation_mode: mode,
        assignee_usernames: assignee_usernames
      )
    end

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    it 'does not change assignees if the resource is not accessible to the assignees' do
      resource.project.add_developer(user)

      expect { subject }.not_to change { resource.reload.assignee_ids }
    end

    it 'returns an operational error if the resource is not accessible to the assignees' do
      resource.project.add_developer(user)

      result = subject

      expect(result[:errors]).to include a_string_matching(/Cannot assign/)
    end

    context 'when the user can update the resource' do
      before do
        resource.project.add_developer(assignee)
        resource.project.add_developer(assignee2)
        resource.project.add_developer(user)
      end

      it 'replaces the assignee' do
        resource.assignees = [assignee2]
        resource.save!

        expect(mutated_resource).to eq(resource)
        expect(mutated_resource.assignees).to contain_exactly(assignee)
        expect(subject[:errors]).to be_empty
      end

      it 'returns errors when resource could not be updated' do
        allow(resource).to receive(:errors_on_object).and_return(['foo'])

        expect(subject[:errors]).not_to match_array(['foo'])
      end

      context 'when passing an empty assignee list' do
        let(:assignee_usernames) { [] }

        before do
          resource.assignees = [assignee]
          resource.save!
        end

        it 'removes all assignees' do
          expect(mutated_resource).to eq(resource)
          expect(mutated_resource.assignees).to eq([])
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "append" as true' do
        subject do
          mutation.resolve(
            project_path: resource.project.full_path,
            iid: resource.iid,
            assignee_usernames: assignee_usernames,
            operation_mode: Types::MutationOperationModeEnum.enum[:append]
          )
        end

        before do
          resource.assignees = [assignee2]
          resource.save!

          # In CE, APPEND is a NOOP as you can't have multiple assignees
          # We test multiple assignment in EE specs
          if resource.is_a?(MergeRequest)
            stub_licensed_features(multiple_merge_request_assignees: false)
          else
            stub_licensed_features(multiple_issue_assignees: false)
          end
        end

        it 'is a NO-OP in FOSS' do
          expect(mutated_resource).to eq(resource)
          expect(mutated_resource.assignees).to contain_exactly(assignee2)
          expect(subject[:errors]).to be_empty
        end
      end

      context 'when passing "remove" as true' do
        before do
          resource.assignees = [assignee]
          resource.save!
        end

        it 'removes named assignee' do
          mutated_resource = mutation.resolve(
            project_path: resource.project.full_path,
            iid: resource.iid,
            assignee_usernames: assignee_usernames,
            operation_mode: Types::MutationOperationModeEnum.enum[:remove]
          )[resource.class.name.underscore.to_sym]

          expect(mutated_resource).to eq(resource)
          expect(mutated_resource.assignees).to eq([])
          expect(subject[:errors]).to be_empty
        end

        it 'does not remove unnamed assignee' do
          mutated_resource = mutation.resolve(
            project_path: resource.project.full_path,
            iid: resource.iid,
            assignee_usernames: [assignee2.username],
            operation_mode: Types::MutationOperationModeEnum.enum[:remove]
          )[resource.class.name.underscore.to_sym]

          expect(mutated_resource).to eq(resource)
          expect(mutated_resource.assignees).to contain_exactly(assignee)
          expect(subject[:errors]).to be_empty
        end
      end
    end
  end
end
