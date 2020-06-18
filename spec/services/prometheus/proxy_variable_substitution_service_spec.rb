# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::ProxyVariableSubstitutionService do
  describe '#execute' do
    let_it_be(:environment) { create(:environment) }

    let(:params_keys) { { query: 'up{environment="{{ci_environment_slug}}"}' } }
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
            query: 'up{environment="{{ci_environment_slug}}"}'
          ).permit!
        )
      end
    end

    context 'with predefined variables' do
      context 'with nil query' do
        let(:params_keys) { {} }

        it_behaves_like 'success' do
          let(:expected_query) { nil }
        end
      end

      context 'with liquid format' do
        let(:params_keys) do
          { query: 'up{environment="{{ci_environment_slug}}"}' }
        end

        it_behaves_like 'success' do
          let(:expected_query) { %Q[up{environment="#{environment.slug}"}] }
        end
      end
    end

    context 'with custom variables' do
      let(:pod_name) { "pod1" }

      let(:params_keys) do
        {
          query: 'up{pod_name="{{pod_name}}"}',
          variables: { 'pod_name' => pod_name }
        }
      end

      it_behaves_like 'success' do
        let(:expected_query) { %q[up{pod_name="pod1"}] }
      end

      context 'with predefined variables in variables parameter' do
        let(:params_keys) do
          {
            query: 'up{pod_name="{{pod_name}}",env="{{ci_environment_slug}}"}',
            variables: { 'pod_name' => pod_name, 'ci_environment_slug' => 'custom_value' }
          }
        end

        it_behaves_like 'success' do
          # Predefined variable values should not be overwritten by custom variable
          # values.
          let(:expected_query) { "up{pod_name=\"#{pod_name}\",env=\"#{environment.slug}\"}" }
        end
      end

      context 'with invalid variables parameter' do
        let(:params_keys) do
          {
            query: 'up{pod_name="{{pod_name}}"}',
            variables: ['a']
          }
        end

        it_behaves_like 'error', 'Optional parameter "variables" must be a Hash. Ex: variables[key1]=value1'
      end

      context 'with nil variables' do
        let(:params_keys) do
          {
            query: 'up{pod_name="{{pod_name}}"}',
            variables: nil
          }
        end

        it_behaves_like 'success' do
          let(:expected_query) { 'up{pod_name="{{pod_name}}"}' }
        end
      end
    end

    context 'gsub variable substitution tolerance for weirdness' do
      context 'with whitespace around variable' do
        let(:params_keys) do
          {
            query: 'up{' \
                "env1={{ ci_environment_slug}}," \
                "env2={{ci_environment_slug }}," \
                "{{  environment_filter }}" \
              '}'
          }
        end

        it_behaves_like 'success' do
          let(:expected_query) do
            'up{' \
              "env1=#{environment.slug}," \
              "env2=#{environment.slug}," \
              "container_name!=\"POD\",environment=\"#{environment.slug}\"" \
            '}'
          end
        end
      end

      context 'with empty variables' do
        let(:params_keys) do
          { query: "up{env1={{}},env2={{  }}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) { "up{env1={{}},env2={{  }}}" }
        end
      end

      context 'with multiple occurrences of variable in string' do
        let(:params_keys) do
          { query: "up{env1={{ci_environment_slug}},env2={{ci_environment_slug}}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) { "up{env1=#{environment.slug},env2=#{environment.slug}}" }
        end
      end

      context 'with multiple variables in string' do
        let(:params_keys) do
          { query: "up{env={{ci_environment_slug}},{{environment_filter}}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) do
            "up{env=#{environment.slug}," \
            "container_name!=\"POD\",environment=\"#{environment.slug}\"}"
          end
        end
      end

      context 'with unknown variables in string' do
        let(:params_keys) { { query: "up{env={{env_slug}}}" } }

        it_behaves_like 'success' do
          let(:expected_query) { "up{env={{env_slug}}}" }
        end
      end

      context 'with unknown and known variables in string' do
        let(:params_keys) do
          { query: "up{env={{ci_environment_slug}},other_env={{env_slug}}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) { "up{env=#{environment.slug},other_env={{env_slug}}}" }
        end
      end
    end

    context '__range' do
      let(:params_keys) do
        {
          query: 'topk(5, sum by (method) (rate(rest_client_requests_total[{{__range}}])))',
          start_time: '2020-05-29T08:19:07.142Z',
          end_time: '2020-05-29T16:19:07.142Z'
        }
      end

      it_behaves_like 'success' do
        let(:expected_query) { "topk(5, sum by (method) (rate(rest_client_requests_total[#{8.hours.to_i}s])))" }
      end
    end
  end
end
