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
      let(:params_keys) { { query: 'up{%{environment_filter}}' } }

      it_behaves_like 'success' do
        let(:expected_query) do
          %Q[up{container_name!="POD",environment="#{environment.slug}"}]
        end
      end

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

      context 'with ruby and liquid formats' do
        let(:params_keys) do
          { query: 'up{%{environment_filter},env2="{{ci_environment_slug}}"}' }
        end

        it_behaves_like 'success' do
          let(:expected_query) do
            %Q[up{container_name!="POD",environment="#{environment.slug}",env2="#{environment.slug}"}]
          end
        end
      end
    end

    context 'with custom variables' do
      let(:pod_name) { "pod1" }

      let(:params_keys) do
        {
          query: 'up{pod_name="{{pod_name}}"}',
          variables: ['pod_name', pod_name]
        }
      end

      it_behaves_like 'success' do
        let(:expected_query) { %q[up{pod_name="pod1"}] }
      end

      context 'with ruby variable interpolation format' do
        let(:params_keys) do
          {
            query: 'up{pod_name="%{pod_name}"}',
            variables: ['pod_name', pod_name]
          }
        end

        it_behaves_like 'success' do
          # Custom variables cannot be used with the Ruby interpolation format.
          let(:expected_query) { "up{pod_name=\"%{pod_name}\"}" }
        end
      end

      context 'with predefined variables in variables parameter' do
        let(:params_keys) do
          {
            query: 'up{pod_name="{{pod_name}}",env="{{ci_environment_slug}}"}',
            variables: ['pod_name', pod_name, 'ci_environment_slug', 'custom_value']
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

        it_behaves_like 'error', 'Optional parameter "variables" must be an ' \
          'array of keys and values. Ex: [key1, value1, key2, value2]'
      end

      context 'with nil variables' do
        let(:params_keys) do
          {
            query: 'up{pod_name="{{pod_name}}"}',
            variables: nil
          }
        end

        it_behaves_like 'success' do
          let(:expected_query) { 'up{pod_name=""}' }
        end
      end

      context 'with ruby and liquid variables' do
        let(:params_keys) do
          {
            query: 'up{env1="%{ruby_variable}",env2="{{ liquid_variable }}"}',
            variables: %w(ruby_variable value liquid_variable env_slug)
          }
        end

        it_behaves_like 'success' do
          # It should replace only liquid variables with their values
          let(:expected_query) { %q[up{env1="%{ruby_variable}",env2="env_slug"}] }
        end
      end
    end

    context 'with liquid tags and ruby format variables' do
      let(:params_keys) do
        {
          query: 'up{ {% if true %}env1="%{ci_environment_slug}",' \
            'env2="{{ci_environment_slug}}"{% endif %} }'
        }
      end

      # The following spec will fail and should be changed to a 'success' spec
      # once we remove support for the Ruby interpolation format.
      # https://gitlab.com/gitlab-org/gitlab/issues/37990
      #
      # Liquid tags `{% %}` cannot be used currently because the Ruby `%`
      # operator raises an error when it encounters a Liquid `{% %}` tag in the
      # string.
      #
      # Once we remove support for the Ruby format, users can start using
      # Liquid tags.

      it_behaves_like 'error', 'Malformed string'
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

    context 'when liquid template rendering raises error' do
      before do
        liquid_service = instance_double(TemplateEngines::LiquidService)

        allow(TemplateEngines::LiquidService).to receive(:new).and_return(liquid_service)
        allow(liquid_service).to receive(:render).and_raise(
          TemplateEngines::LiquidService::RenderError, 'error message'
        )
      end

      it_behaves_like 'error', 'error message'
    end
  end
end
