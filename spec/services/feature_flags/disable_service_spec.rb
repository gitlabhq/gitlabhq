# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::DisableService do
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

    context 'with params to disable default strategy on prd scope' do
      let(:params) do
        {
          name: 'awesome',
          environment_scope: 'prd',
          strategy: { name: 'userWithId', parameters: { 'userIds': 'User:1' } }.deep_stringify_keys
        }
      end

      context 'when there is a persisted feature flag' do
        let!(:feature_flag) { create_flag(project, params[:name]) }

        context 'when there is a persisted scope' do
          let!(:scope) do
            create_scope(feature_flag, params[:environment_scope], true, strategies)
          end

          context 'when there is a persisted strategy' do
            let(:strategies) do
              [
                { name: 'userWithId', parameters: { 'userIds': 'User:1' } }.deep_stringify_keys,
                { name: 'userWithId', parameters: { 'userIds': 'User:2' } }.deep_stringify_keys
              ]
            end

            it 'deletes the specified strategy' do
              subject

              scope.reload
              expect(scope.strategies.count).to eq(1)
              expect(scope.strategies).not_to include(params[:strategy])
            end

            context 'when strategies will be empty' do
              let(:strategies) { [params[:strategy]] }

              it 'deletes the persisted scope' do
                subject

                expect(feature_flag.scopes.exists?(environment_scope: params[:environment_scope]))
                  .to eq(false)
              end
            end
          end

          context 'when there is no persisted strategy' do
            let(:strategies) { [{ name: 'default', parameters: {} }] }

            it 'returns error' do
              expect(subject[:status]).to eq(:error)
              expect(subject[:message]).to include('Strategy not found')
            end
          end
        end

        context 'when there is no persisted scope' do
          it 'returns error' do
            expect(subject[:status]).to eq(:error)
            expect(subject[:message]).to include('Feature Flag Scope not found')
          end
        end
      end

      context 'when there is no persisted feature flag' do
        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to include('Feature Flag not found')
        end
      end
    end
  end
end
