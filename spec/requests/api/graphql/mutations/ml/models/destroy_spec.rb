# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a model', feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:model) { create(:ml_models) }
  let_it_be(:user) { create(:user) }

  let(:project) { model.project }
  let(:id) { model.to_global_id.to_s }

  let(:query) do
    <<~GQL
      message
      errors
    GQL
  end

  let(:params) { { project_path: project.full_path, id: id } }
  let(:mutation) { graphql_mutation(:ml_model_destroy, params, query) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_destroy) }

  shared_examples 'destroying the model' do
    it 'destroys model' do
      expect(::Ml::DestroyModelService).to receive(:new).with(model, user).and_call_original

      expect { mutation_request }.to change { ::Ml::Model.count }.by(-1)
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'denying the mutation request' do
    it 'does not delete the model' do
      expect(::Ml::DestroyModelService).not_to receive(:new)

      expect { mutation_request }.to not_change { ::Ml::Model.count }

      expect(mutation_response).to be_nil
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'model was not found' do
    it 'does not delete the model' do
      expect(::Ml::DestroyModelService).not_to receive(:new)

      expect { mutation_request }.to not_change { ::Ml::Model.count }

      expect(mutation_response["errors"]).to match_array(['Model not found'])
    end

    it_behaves_like 'returning response status', :success
  end

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :mutation_behavior) do
        :maintainer | 'destroying the model'
        :developer  | 'destroying the model'
        :reporter   | 'denying the mutation request'
        :guest      | 'denying the mutation request'
        :anonymous  | 'denying the mutation request'
      end

      with_them do
        before do
          project.public_send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:mutation_behavior]
      end
    end

    context 'with authorized user' do
      before do
        project.add_maintainer(user)
      end

      context 'with invalid id' do
        let(:params) { { project_path: project.full_path, id: "gid://gitlab/Ml::Model/#{non_existing_record_id}" } }

        it_behaves_like 'model was not found'
      end

      context 'when deleting a model works but has a warning' do
        it 'adds the warning as message' do
          service_double = double
          allow(::Ml::DestroyModelService).to receive(:new).and_return(service_double)
          allow(service_double).to receive(:execute).and_return(ServiceResponse.success(message: "A message"))

          mutation_request

          expect(mutation_response['message']).to eq("A message")
        end
      end

      context 'when an error occurs' do
        it 'returns the errors in the response' do
          allow_next_found_instance_of(::Ml::Model) do |model|
            allow(model).to receive(:destroy).and_return(nil)
            errors = ActiveModel::Errors.new(model).tap { |e| e.add(:id, 'some error') }
            allow(model).to receive(:errors).and_return(errors)
          end

          mutation_request

          expect(mutation_response['errors']).to match_array(['Id some error'])
        end
      end
    end
  end
end
