# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::ProxyVariableSubstitutionService do
  describe '#execute' do
    let_it_be(:environment) { create(:environment) }

    let(:params_keys) { { query: "up{environment=\"#{w('ci_environment_slug')}\"}" } }
    let(:params) { ActionController::Parameters.new(params_keys).permit! }
    let(:result) { subject.execute }

    subject { described_class.new(environment, params) }

    # Default implementation of the w method. The `success` shared example overrides
    # this implementation to test the Ruby and Liquid syntaxes.
    # This method wraps the given variable name in the variable interpolation
    # syntax. Using this method along with the `success` shared example allows
    # a spec to test both syntaxes.
    def w(variable_name)
      "%{#{variable_name}}"
    end

    shared_examples 'replaces variables with values' do
      it 'replaces variables with values' do
        expect(result[:status]).to eq(:success)
        expect(result[:params][:query]).to eq(expected_query)
      end
    end

    shared_examples 'success' do
      context 'with Ruby syntax `${}`' do
        it_behaves_like 'replaces variables with values'

        def w(variable_name)
          "%{#{variable_name}}"
        end
      end

      context 'with Liquid syntax `{{}}`' do
        it_behaves_like 'replaces variables with values'

        def w(variable_name)
          "{{#{variable_name}}}"
        end
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
      # Liquid replaces the opening brace of the query as well, if there is no space
      # between `up{` and the rest of the string.
      let(:params_keys) { { query: "up{ #{w('environment_filter')}}" } }

      it_behaves_like 'success' do
        let(:expected_query) do
          %Q[up{ container_name!="POD",environment="#{environment.slug}"}]
        end
      end

      context 'with nil query' do
        let(:params_keys) { {} }

        it_behaves_like 'success' do
          let(:expected_query) { nil }
        end
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

    context 'with custom variables' do
      let(:pod_name) { "pod1" }

      let(:params_keys) do
        {
          query: "up{pod_name=\"#{w('pod_name')}\"}",
          variables: ['pod_name', pod_name]
        }
      end

      it_behaves_like 'success' do
        let(:expected_query) { %q[up{pod_name="pod1"}] }
      end

      context 'with predefined variables in variables parameter' do
        let(:params_keys) do
          {
            query: "up{pod_name=\"#{w('pod_name')}\",env=\"#{w('ci_environment_slug')}\"}",
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
            query: "up{pod_name=\"#{w('pod_name')}\"}",
            variables: ['a']
          }
        end

        it_behaves_like 'error', 'Optional parameter "variables" must be an ' \
          'array of keys and values. Ex: [key1, value1, key2, value2]'
      end

      context 'with nil variables' do
        let(:params_keys) do
          {
            query: "up{pod_name=\"%{pod_name}\"}",
            variables: nil
          }
        end

        it_behaves_like 'replaces variables with values' do
          let(:expected_query) { "up{pod_name=\"%{pod_name}\"}" }
        end
      end
    end

    context 'gsub variable substitution tolerance for weirdness' do
      context 'with whitespace around variable' do
        let(:params_keys) do
          {
            query: 'up{' \
                "env1=#{w(' ci_environment_slug')}," \
                "env2=#{w('ci_environment_slug ')}," \
                "#{w('  environment_filter ')}" \
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

      context 'with liquid tags and ruby format variables' do
        let(:params_keys) do
          {
            query: 'up{ {% if true %}env1="%{ci_environment_slug}",' \
              'env2="{{ci_environment_slug}}"{% endif %} }'
          }
        end

        it_behaves_like 'replaces variables with values' do
          let(:expected_query) { "up{ env1=\"#{environment.slug}\",env2=\"#{environment.slug}\" }" }
        end
      end

      context 'with empty variables' do
        let(:params_keys) do
          { query: "up{env1=%{},env2=%{  }}" }
        end

        it_behaves_like 'replaces variables with values' do
          let(:expected_query) { "up{env1=%{},env2=%{  }}" }
        end
      end

      context 'with multiple occurrences of variable in string' do
        let(:params_keys) do
          { query: "up{env1=#{w('ci_environment_slug')},env2=#{w('ci_environment_slug')}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) { "up{env1=#{environment.slug},env2=#{environment.slug}}" }
        end
      end

      context 'with multiple variables in string' do
        let(:params_keys) do
          { query: "up{env=#{w('ci_environment_slug')},#{w('environment_filter')}}" }
        end

        it_behaves_like 'success' do
          let(:expected_query) do
            "up{env=#{environment.slug}," \
            "container_name!=\"POD\",environment=\"#{environment.slug}\"}"
          end
        end
      end

      context 'with unknown variables in string' do
        let(:params_keys) { { query: "up{env=#{w('env_slug')}}" } }

        it_behaves_like 'replaces variables with values' do
          let(:expected_query) { "up{env=%{env_slug}}" }
        end
      end

      # The ruby % operator will not replace known variables if there are unknown
      # variables also in the string. It doesn't raise an error
      # (though the `sprintf` and `format` methods do).
      # Fortunately, we do not use the % operator anymore.
      context 'with unknown and known variables in string' do
        let(:params_keys) do
          { query: "up{env=%{ci_environment_slug},other_env=%{env_slug}}" }
        end

        it_behaves_like 'replaces variables with values' do
          let(:expected_query) { "up{env=#{environment.slug},other_env=#{w('env_slug')}}" }
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
