# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::TotalRiskScore, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }
  let(:valid_svg) do
    svg_content = <<~SVG.strip
      <svg width="590" height="466" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 590 466">
      <rect width="590" height="466" x="0" y="0" fill="none"></rect>
      <text x="295" y="259">45.8</text>
      </svg>
    SVG

    "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg_content)}"
  end

  describe '.render' do
    it 'creates a new instance and calls render' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:render)
      end
      described_class.render(pdf, data: valid_svg)
    end
  end

  describe '#initialize' do
    it 'sets the pdf and data' do
      instance = described_class.new(pdf, valid_svg)
      expect(instance.instance_variable_get(:@pdf)).to eq(pdf)
    end

    it 'processes the raw data' do
      instance = described_class.new(pdf, valid_svg)
      expect(instance.instance_variable_get(:@data)).to include('<svg')
    end
  end

  describe '#render' do
    context 'when data is blank' do
      it 'returns :noop' do
        instance = described_class.new(pdf, nil)
        expect(instance.render).to eq(:noop)
      end
    end

    context 'when data is present' do
      it 'calls draw_background' do
        instance = described_class.new(pdf, valid_svg)
        expect(instance).to receive(:draw_background).and_call_original
        instance.render
      end

      it 'calls draw_title' do
        instance = described_class.new(pdf, valid_svg)
        expect(instance).to receive(:draw_title).and_call_original
        instance.render
      end

      it 'calls draw_description' do
        instance = described_class.new(pdf, valid_svg)
        expect(instance).to receive(:draw_description).and_call_original
        instance.render
      end

      it 'calls draw_svg' do
        instance = described_class.new(pdf, valid_svg)
        expect(instance).to receive(:draw_svg).and_call_original
        instance.render
      end
    end
  end

  describe '#draw_background' do
    it 'fills the background with light gray color' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:fill_color).with('F9F9F9')
      expect(pdf).to receive(:fill_rectangle)
      instance.send(:draw_background)
    end

    it 'saves and restores graphics state' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:save_graphics_state)
      expect(pdf).to receive(:restore_graphics_state)
      instance.send(:draw_background)
    end
  end

  describe '#draw_title' do
    it 'renders the title text' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:text_box).with(
        'Total Risk Score',
        hash_including(
          style: :bold,
          size: 14,
          align: :left
        )
      )
      instance.send(:draw_title)
    end

    it 'moves down after drawing title' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:move_down).with(20)
      instance.send(:draw_title)
    end
  end

  describe '#draw_description' do
    it 'renders the description text' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:text_box).with(
        "The overall risk score for your organization based on vulnerability severity and age.",
        hash_including(
          size: 10,
          align: :left
        )
      )
      instance.send(:draw_description)
    end

    it 'moves down after drawing description' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:move_down).with(10)
      instance.send(:draw_description)
    end
  end

  describe '#draw_svg' do
    it 'renders the SVG with correct parameters' do
      instance = described_class.new(pdf, valid_svg)
      expect(pdf).to receive(:svg).with(
        instance.instance_variable_get(:@data),
        height: 100,
        position: :center
      )
      instance.send(:draw_svg, 100)
    end
  end

  describe '#process_raw' do
    context 'when data is blank' do
      it 'returns nil' do
        instance = described_class.new(pdf, nil)
        expect(instance.send(:process_raw, nil)).to be_nil
      end
    end

    context 'when data is a string' do
      it 'extracts the SVG from the string' do
        instance = described_class.new(pdf, valid_svg)
        result = instance.send(:process_raw, valid_svg)
        expect(result).to include('<svg')
        expect(result).to include('</svg>')
      end

      it 'removes newlines from the SVG' do
        svg_with_newlines = "<svg>\n<rect/>\n</svg>"
        instance = described_class.new(pdf, svg_with_newlines)
        result = instance.send(:process_raw, svg_with_newlines)
        expect(result).not_to include("\n")
      end
    end

    context 'when data is a hash with svg key' do
      it 'extracts the SVG from the hash' do
        data = { 'svg' => valid_svg }
        instance = described_class.new(pdf, data)
        result = instance.send(:process_raw, data)
        expect(result).to include('<svg')
      end

      it 'handles symbol keys' do
        data = { svg: valid_svg }
        instance = described_class.new(pdf, data)
        result = instance.send(:process_raw, data)
        expect(result).to include('<svg')
      end
    end

    context 'when data is URL-encoded' do
      it 'decodes the URL-encoded SVG' do
        svg_content = <<~SVG.strip
          <svg width="590" height="466" xmlns="http://www.w3.org/2000/svg">
          <rect width="590" height="466" fill="none"/>
          </svg>
        SVG

        encoded_svg = "data:image/svg+xml;charset=UTF-8,#{ERB::Util.url_encode(svg_content)}"
        instance = described_class.new(pdf, encoded_svg)
        result = instance.send(:process_raw, encoded_svg)

        expect(result).to include('<svg')
        expect(result).to include('</svg>')
        expect(result).not_to include('data:image')
      end
    end

    context 'when SVG has no newlines' do
      it 'still processes correctly without crashing' do
        svg_no_newlines = '<svg><rect/></svg>'
        instance = described_class.new(pdf, svg_no_newlines)
        result = instance.send(:process_raw, svg_no_newlines)

        expect(result).to include('<svg')
        expect(result).to include('</svg>')
      end
    end

    context 'when SVG string contains multiple svg tags' do
      it 'extracts only the first SVG' do
        svg_with_multiple = '<svg><rect/></svg><svg><circle/></svg>'
        instance = described_class.new(pdf, svg_with_multiple)
        result = instance.send(:process_raw, svg_with_multiple)

        expect(result).to include('<rect/>')
        expect(result).not_to include('<circle/>')
      end
    end

    context 'when SVG is blank after extraction' do
      it 'returns nil' do
        instance = described_class.new(pdf, '<div></div>')
        result = instance.send(:process_raw, '<div></div>')
        expect(result).to be_nil
      end
    end
  end
end
