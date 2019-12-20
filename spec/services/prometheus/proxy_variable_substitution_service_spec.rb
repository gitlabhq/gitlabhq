# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::ProxyVariableSubstitutionService do
  describe '#execute' do
    let_it_be(:environment) { create(:environment) }

    let(:params_keys) { { query: 'up{environment="%{ci_environment_slug}"}' } }
    let(:params) { ActionController::Parameters.new(params_keys).permit! }
    let(:result) { subject.execute }

    subject { described_class.new(environment, params) }

    shared_examples 'success' do
      it 'replaces variables with values' do
        expect(result[:status]).to eq(:success)
        expect(result[:params][:query]).to eq(expected_query)
      end
    end

    shared_examples 'error' do |message|
      it 'returns error' do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(message)
      end
    end

    context 'does not alter params passed to the service' do
      it do
        subject.execute

        expect(params).to eq(
          ActionController::Parameters.new(
            query: 'up{environment="%{ci_environment_slug}"}'
          ).permit!
        )
      end
    end

    context 'with predefined variables' do
      it_behaves_like 'success' do
        let(:expected_query) { %Q[up{environment="#{environment.slug}"}] }
      end

      context 'with nil query' do
        let(:params_keys) { {} }

        it_behaves_like 'success' do
          let(:expected_query) { nil }
        end
      end
    end

    context 'ruby template rendering' do
      let(:params_keys) do
        { query: 'up{env=%{ci_environment_slug},%{environment_filter}}' }
      end

      it_behaves_like 'success' do
        let(:expected_query) do
          "up{env=#{environment.slug},container_name!=\"POD\"," \
          "environment=\"#{environment.slug}\"}"
        end
      end

      context 'with multiple occurrences of variable in string' do
        let(:params_keys) do
          { query: 'up{env1=%{ci_environment_slug},env2=%{ci_environment_slug}}' }
        end

        it_behaves_like 'success' do
          let(:expected_query) { "up{env1=#{environment.slug},env2=#{environment.slug}}" }
        end
      end

      context 'with multiple variables in string' do
        let(:params_keys) do
          { query: 'up{env=%{ci_environment_slug},%{environment_filter}}' }
        end

        it_behaves_like 'success' do
          let(:expected_query) do
            "up{env=#{environment.slug}," \
            "container_name!=\"POD\",environment=\"#{environment.slug}\"}"
          end
        end
      end

      context 'with unknown variables in string' do
        let(:params_keys) { { query: 'up{env=%{env_slug}}' } }

        it_behaves_like 'success' do
          let(:expected_query) { 'up{env=%{env_slug}}' }
        end
      end

      # This spec is needed if there are multiple keys in the context provided
      # by `Gitlab::Prometheus::QueryVariables.call(environment)` which is
      # passed to the Ruby `%` operator.
      # If the number of keys in the context is one, there is no need for
      # this spec.
      context 'with extra variables in context' do
        let(:params_keys) { { query: 'up{env=%{ci_environment_slug}}' } }

        it_behaves_like 'success' do
          let(:expected_query) { "up{env=#{environment.slug}}" }
        end

        it 'has more than one variable in context' do
          expect(Gitlab::Prometheus::QueryVariables.call(environment).size).to be > 1
        end
      end

      # The ruby % operator will not replace known variables if there are unknown
      # variables also in the string. It doesn't raise an error
      # (though the `sprintf` and `format` methods do).
      context 'with unknown and known variables in string' do
        let(:params_keys) do
          { query: 'up{env=%{ci_environment_slug},other_env=%{env_slug}}' }
        end

        it_behaves_like 'success' do
          let(:expected_query) { 'up{env=%{ci_environment_slug},other_env=%{env_slug}}' }
        end
      end

      context 'when rendering raises error' do
        context 'when TypeError is raised' do
          let(:params_keys) { { query: '{% a %}' } }

          it_behaves_like 'error', 'Malformed string'
        end

        context 'when ArgumentError is raised' do
          let(:params_keys) { { query: '%<' } }

          it_behaves_like 'error', 'Malformed string'
        end
      end
    end
  end
end
