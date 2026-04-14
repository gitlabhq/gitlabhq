# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::PDF::Security::BaseSvgChart, feature_category: :vulnerability_management do
  # Concrete subclass for testing - base class is abstract
  let(:test_chart_class) do
    Class.new(described_class) do
      private

      def total_height
        300
      end

      def title_text
        'Test Title'
      end

      def description_text
        'Test description'
      end
    end
  end

  let(:pdf) { Prawn::Document.new }
  let(:valid_svg) do
    encode_svg(<<~SVG.strip)
      <svg width="590" height="466" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 590 466">
      <rect width="590" height="466" x="0" y="0" fill="none"></rect>
      </svg>
    SVG
  end

  let(:wide_svg) { encode_svg('<svg width="1000" height="10"><rect/></svg>') }
  let(:tall_svg) { encode_svg('<svg width="10" height="1000"><rect/></svg>') }
  let(:no_dimensions_svg) { '<svg xmlns="http://www.w3.org/2000/svg"><rect/></svg>' }
  let(:zero_height_svg) { '<svg width="100" height="0" xmlns="http://www.w3.org/2000/svg"><rect/></svg>' }

  def encode_svg(content)
    "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(content)}"
  end

  describe '.render' do
    it 'creates a new instance and calls render' do
      expect_next_instance_of(test_chart_class) do |chart|
        expect(chart).to receive(:render).and_call_original
      end
      test_chart_class.render(pdf, data: valid_svg)
    end

    context 'when data is blank' do
      it 'returns :noop without rendering anything' do
        expect(test_chart_class.render(pdf, data: nil)).to eq(:noop)
      end

      it 'does not modify the PDF content' do
        initial_length = pdf.page.content.stream.length
        test_chart_class.render(pdf, data: nil)
        expect(pdf.page.content.stream.length).to eq(initial_length)
      end
    end

    context 'with invalid data' do
      it 'returns :noop for empty string' do
        expect(test_chart_class.render(pdf, data: '')).to eq(:noop)
      end

      it 'returns :noop for non-SVG content' do
        expect(test_chart_class.render(pdf, data: '<div></div>')).to eq(:noop)
      end

      it 'returns :noop for hash with blank svg value' do
        expect(test_chart_class.render(pdf, data: { svg: '' })).to eq(:noop)
      end

      it 'returns :noop for hash without svg key' do
        expect(test_chart_class.render(pdf, data: {})).to eq(:noop)
      end

      it 'return :noop for svg key with nil value' do
        expect(test_chart_class.render(pdf, data: { svg: nil })).to eq(:noop)
      end
    end
  end

  describe '#render' do
    context 'when data is blank' do
      it 'returns :noop' do
        expect(test_chart_class.new(pdf, nil).render).to eq(:noop)
      end
    end

    context 'when data is present' do
      it 'adds content to the PDF' do
        expect { test_chart_class.render(pdf, data: valid_svg) }
          .to change { pdf.page.content.stream.length }
      end

      it 'draws a light gray background' do
        allow(pdf).to receive(:fill_color).and_call_original
        expect(pdf).to receive(:fill_color).with('F9F9F9').and_call_original
        test_chart_class.render(pdf, data: valid_svg)
      end

      it 'completes without errors' do
        expect { test_chart_class.render(pdf, data: valid_svg) }.not_to raise_error
      end
    end

    context 'with SVG aspect ratio fitting within available height at full width' do
      it 'renders the SVG constrained by width' do
        expect(pdf).to receive(:svg).with(anything, hash_including(width: anything)).and_call_original
        test_chart_class.render(pdf, data: wide_svg)
      end
    end

    context 'with SVG aspect ratio that would overflow at full width' do
      it 'renders the SVG constrained by height instead' do
        expect(pdf).to receive(:svg).with(anything, hash_including(height: anything)).and_call_original
        test_chart_class.render(pdf, data: tall_svg)
      end
    end

    context 'when the SVG has no width or height attributes' do
      it 'renders the SVG constrained by width' do
        expect(pdf).to receive(:svg).with(anything, hash_including(width: anything)).and_call_original
        test_chart_class.render(pdf, data: no_dimensions_svg)
      end
    end

    context 'when the SVG has zero height' do
      it 'renders the SVG constrained by width' do
        expect(pdf).to receive(:svg).with(anything, hash_including(width: anything)).and_call_original
        test_chart_class.render(pdf, data: zero_height_svg)
      end
    end
  end

  describe '#initialize' do
    it 'accepts a pdf and data' do
      expect { test_chart_class.new(pdf, valid_svg) }.not_to raise_error
    end

    context 'with URL-encoded SVG' do
      it 'decodes and stores the SVG' do
        instance = test_chart_class.new(pdf, valid_svg)
        expect(instance.instance_variable_get(:@data)).to include('<svg')
      end
    end

    context 'with a hash containing an svg key' do
      it 'extracts the SVG from a string key' do
        instance = test_chart_class.new(pdf, { 'svg' => valid_svg })
        expect(instance.instance_variable_get(:@data)).to include('<svg')
      end

      it 'extracts the SVG from a symbol key' do
        instance = test_chart_class.new(pdf, { svg: valid_svg })
        expect(instance.instance_variable_get(:@data)).to include('<svg')
      end
    end

    context 'with a plain SVG string' do
      it 'stores the SVG' do
        instance = test_chart_class.new(pdf, '<svg><rect/></svg>')
        expect(instance.instance_variable_get(:@data)).to include('<svg')
      end
    end

    context 'with nil data' do
      it 'stores nil' do
        instance = test_chart_class.new(pdf, nil)
        expect(instance.instance_variable_get(:@data)).to be_nil
      end
    end

    context 'with non-SVG content' do
      it 'stores nil' do
        instance = test_chart_class.new(pdf, '<div></div>')
        expect(instance.instance_variable_get(:@data)).to be_nil
      end
    end

    context 'with a multiline SVG' do
      it 'correctly parses SVGs that contain newlines' do
        svg = "<svg width=\"100\" height=\"100\">\n  <rect/>\n</svg>"
        instance = test_chart_class.new(pdf, svg)
        expect(instance.instance_variable_get(:@data)).to include('<svg')
      end

      it 'does not return nil when the SVG has no newlines' do
        svg = '<svg width="100" height="100"><rect/></svg>'
        instance = test_chart_class.new(pdf, svg)
        expect(instance.instance_variable_get(:@data)).not_to be_nil
      end
    end

    it 'extracts only the first SVG when multiple are present' do
      instance = test_chart_class.new(pdf, '<svg><rect/></svg><svg><circle/></svg>')
      data = instance.instance_variable_get(:@data)
      expect(data).to include('<rect/>')
      expect(data).not_to include('<circle/>')
    end

    context 'when the subclass provides css_translations' do
      let(:translating_class) do
        Class.new(described_class) do
          private

          def total_height
            300
          end

          def title_text
            'Title'
          end

          def description_text
            'Desc'
          end

          def css_translations
            [['var(--some-color)', '#ff0000']]
          end
        end
      end

      it 'substitutes CSS variables in the stored SVG' do
        svg = '<svg width="100" height="100"><path stroke="var(--some-color)"/></svg>'
        instance = translating_class.new(pdf, svg)
        data = instance.instance_variable_get(:@data)
        expect(data).to include('#ff0000')
        expect(data).not_to include('var(--some-color)')
      end
    end

    context 'when no css_translations are defined' do
      it 'preserves CSS variables in the stored SVG unchanged' do
        svg = '<svg width="100" height="100"><path stroke="var(--some-color)"/></svg>'
        instance = test_chart_class.new(pdf, svg)
        expect(instance.instance_variable_get(:@data)).to include('var(--some-color)')
      end
    end
  end

  describe 'abstract interface' do
    it 'raises NotImplementedError when total_height is not implemented' do
      expect { described_class.new(pdf, valid_svg).render }.to raise_error(NotImplementedError)
    end

    it 'raises NotImplementedError when title_text is not implemented' do
      klass = Class.new(described_class) do
        private

        def total_height
          300
        end
      end

      expect { klass.new(pdf, valid_svg).render }.to raise_error(NotImplementedError, /title_text/)
    end

    it 'raises NotImplementedError when description_text is not implemented' do
      klass = Class.new(described_class) do
        private

        def total_height
          300
        end

        def title_text
          'title'
        end
      end

      expect { klass.new(pdf, valid_svg).render }.to raise_error(NotImplementedError, /description_text/)
    end
  end
end
