# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a model version', feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be_with_reload(:model_version) { create(:ml_model_versions) }
  let_it_be(:user) { create(:user) }

  let(:project) { model_version.project }
  let(:id) { model_version.to_global_id.to_s }

  let(:query) do
    <<~GQL
      modelVersion {
        id
      }
      errors
    GQL
  end

  let(:params) { { id: id } }
  let(:mutation) { graphql_mutation(:ml_model_version_delete, params, query) }
  let(:mutation_response) { graphql_mutation_response(:ml_model_version_delete) }

  shared_examples 'destroying the model' do
    it 'destroys model' do
      expect(::Ml::DestroyModelVersionService).to receive(:new).with(model_version, user).and_call_original

      expect { mutation_request }.to change { ::Ml::ModelVersion.count }.by(-1)
      expect(mutation_response['modelVersion']).to eq({ "id" => GitlabSchema.id_from_object(model_version).to_s })
    end

    it_behaves_like 'returning response status', :success
  end

  shared_examples 'model version was not found' do
    it 'does not delete the model' do
      expect(::Ml::DestroyModelVersionService).not_to receive(:new)

      expect { mutation_request }.to not_change { ::Ml::ModelVersion.count }

      expect(mutation_response["errors"]).to match_array(['Model version not found'])
    end

    it_behaves_like 'returning response status', :success
  end

  describe 'post graphql mutation' do
    subject(:mutation_request) { post_graphql_mutation(mutation, current_user: user) }

    context 'with valid id' do
      where(:user_role, :mutation_behavior) do
        :maintainer | 'destroying the model'
        :developer  | 'destroying the model'
        :reporter   | 'a mutation that returns a top-level access error'
        :guest      | 'a mutation that returns a top-level access error'
        :anonymous  | 'a mutation that returns a top-level access error'
      end

      with_them do
        let(:current_user) { user }

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
        let(:params) do
          { id: "gid://gitlab/Ml::ModelVersion/#{non_existing_record_id}" }
        end

        it_behaves_like 'model version was not found'
      end

      context 'when an error occurs' do
        it 'returns the errors in the response' do
          allow_next_found_instance_of(::Ml::ModelVersion) do |model|
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
