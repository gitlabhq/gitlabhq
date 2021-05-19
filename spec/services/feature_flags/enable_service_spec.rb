# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::EnableService do
  include FeatureFlagHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:params) { {} }
  let(:service) { described_class.new(project, user, params) }

  before_all do
    project.add_developer(user)
  end

  describe '#execute' do
    subject { service.execute }

    context 'with params to enable default strategy on prd scope' do
      let(:params) do
        {
          name: 'awesome',
          environment_scope: 'prd',
          strategy: { name: 'default', parameters: {} }.stringify_keys
        }
      end

      context 'when there is no persisted feature flag' do
        it 'creates a new feature flag with scope' do
          feature_flag = subject[:feature_flag]
          scope = feature_flag.scopes.find_by_environment_scope(params[:environment_scope])
          expect(subject[:status]).to eq(:success)
          expect(feature_flag.name).to eq(params[:name])
          expect(feature_flag.default_scope).not_to be_active
          expect(scope).to be_active
          expect(scope.strategies).to include(params[:strategy])
        end

        context 'when params include default scope' do
          let(:params) do
            {
              name: 'awesome',
              environment_scope: '*',
              strategy: { name: 'userWithId', parameters: { 'userIds': 'abc' } }.deep_stringify_keys
            }
          end

          it 'create a new feature flag with an active default scope with the specified strategy' do
            feature_flag = subject[:feature_flag]
            expect(subject[:status]).to eq(:success)
            expect(feature_flag.default_scope).to be_active
            expect(feature_flag.default_scope.strategies).to include(params[:strategy])
          end
        end
      end

      context 'when there is a persisted feature flag' do
        let!(:feature_flag) { create_flag(project, params[:name]) }

        context 'when there is no persisted scope' do
          it 'creates a new scope for the persisted feature flag' do
            feature_flag = subject[:feature_flag]
            scope = feature_flag.scopes.find_by_environment_scope(params[:environment_scope])
            expect(subject[:status]).to eq(:success)
            expect(feature_flag.name).to eq(params[:name])
            expect(scope).to be_active
            expect(scope.strategies).to include(params[:strategy])
          end
        end

        context 'when there is a persisted scope' do
          let!(:feature_flag_scope) do
            create_scope(feature_flag, params[:environment_scope], active, strategies)
          end

          let(:active) { true }

          context 'when the persisted scope does not have the specified strategy yet' do
            let(:strategies) { [{ name: 'userWithId', parameters: { 'userIds': 'abc' } }] }

            it 'adds the specified strategy to the scope' do
              subject

              feature_flag_scope.reload
              expect(feature_flag_scope.strategies).to include(params[:strategy])
            end

            context 'when the persisted scope is inactive' do
              let(:active) { false }

              it 'reactivates the scope' do
                expect { subject }
                  .to change { feature_flag_scope.reload.active }.from(false).to(true)
              end
            end
          end

          context 'when the persisted scope has the specified strategy already' do
            let(:strategies) { [params[:strategy]] }

            it 'does not add a duplicated strategy to the scope' do
              expect { subject }
                .not_to change { feature_flag_scope.reload.strategies.count }
            end
          end
        end
      end
    end

    context 'when strategy is not specified in params' do
      let(:params) do
        {
          name: 'awesome',
          environment_scope: 'prd'
        }
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to include('Scopes strategies must be an array of strategy hashes')
      end
    end

    context 'when environment scope is not specified in params' do
      let(:params) do
        {
          name: 'awesome',
          strategy: { name: 'default', parameters: {} }.stringify_keys
        }
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to include("Scopes environment scope can't be blank")
      end
    end

    context 'when name is not specified in params' do
      let(:params) do
        {
          environment_scope: 'prd',
          strategy: { name: 'default', parameters: {} }.stringify_keys
        }
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to include("Name can't be blank")
      end
    end
  end
end
