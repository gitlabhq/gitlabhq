# frozen_string_literal: true

require 'spec_helper'

describe TemplateEngines::LiquidService do
  describe '#render' do
    let(:template) { 'up{env={{ci_environment_slug}}}' }
    let(:result) { subject }

    let_it_be(:slug) { 'env_slug' }

    let_it_be(:context) do
      {
        ci_environment_slug: slug,
        environment_filter: "container_name!=\"POD\",environment=\"#{slug}\""
      }
    end

    subject { described_class.new(template).render(context) }

    it 'with symbol keys in context it substitutes variables' do
      expect(result).to include("up{env=#{slug}")
    end

    context 'with multiple occurrences of variable in template' do
      let(:template) do
        'up{env1={{ci_environment_slug}},env2={{ci_environment_slug}}}'
      end

      it 'substitutes variables' do
        expect(result).to eq("up{env1=#{slug},env2=#{slug}}")
      end
    end

    context 'with multiple variables in template' do
      let(:template) do
        'up{env={{ci_environment_slug}},' \
        '{{environment_filter}}}'
      end

      it 'substitutes all variables' do
        expect(result).to eq(
          "up{env=#{slug}," \
          "container_name!=\"POD\",environment=\"#{slug}\"}"
        )
      end
    end

    context 'with unknown variables in template' do
      let(:template) { 'up{env={{env_slug}}}' }

      it 'does not substitute unknown variables' do
        expect(result).to eq("up{env=}")
      end
    end

    context 'with extra variables in context' do
      let(:template) { 'up{env={{ci_environment_slug}}}' }

      it 'substitutes variables' do
        # If context has only 1 key, there is no need for this spec.
        expect(context.count).to be > 1
        expect(result).to eq("up{env=#{slug}}")
      end
    end

    context 'with unknown and known variables in template' do
      let(:template) { 'up{env={{ci_environment_slug}},other_env={{env_slug}}}' }

      it 'substitutes known variables' do
        expect(result).to eq("up{env=#{slug},other_env=}")
      end
    end

    context 'Liquid errors' do
      shared_examples 'raises RenderError' do |message|
        it do
          expect { result }.to raise_error(described_class::RenderError, message)
        end
      end

      context 'when liquid raises error' do
        let(:template) { 'up{env={{ci_environment_slug}}' }
        let(:liquid_template) { Liquid::Template.new }

        before do
          allow(Liquid::Template).to receive(:parse).with(template).and_return(liquid_template)
          allow(liquid_template).to receive(:render!).and_raise(exception, message)
        end

        context 'raises Liquid::MemoryError' do
          let(:exception) { Liquid::MemoryError }
          let(:message) { 'Liquid error: Memory limits exceeded' }

          it_behaves_like 'raises RenderError', 'Memory limit exceeded while rendering template'
        end

        context 'raises Liquid::Error' do
          let(:exception) { Liquid::Error }
          let(:message) { 'Liquid error: Generic error message' }

          it_behaves_like 'raises RenderError', 'Error rendering query'
        end
      end

      context 'with template that is expensive to render' do
        let(:template) do
          '{% assign loop_count     = 1000 %}'\
          '{% assign padStr  = "0" %}'\
          '{% assign number_to_pad = "1" %}'\
          '{% assign strLength = number_to_pad | size %}'\
          '{% assign padLength = loop_count | minus: strLength %}'\
          '{% if padLength > 0 %}'\
          '  {% assign padded = number_to_pad %}'\
          '  {% for position in (1..padLength) %}'\
          '    {% assign padded = padded | prepend: padStr %}'\
          '  {% endfor %}'\
          '  {{ padded }}'\
          '{% endif %}'
        end

        it_behaves_like 'raises RenderError', 'Memory limit exceeded while rendering template'
      end
    end
  end
end
