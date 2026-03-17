# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::VulnerabilitiesOverTime, feature_category: :vulnerability_management do
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
        expect(instance).to receive(:render).and_call_original
      end
      described_class.render(pdf, data: valid_svg)
    end

    context 'when data is blank' do
      it 'returns :noop without rendering anything' do
        result = described_class.render(pdf, data: nil)
        expect(result).to eq(:noop)
      end

      it 'does not modify the PDF content' do
        initial_stream_length = pdf.page.content.stream.length
        described_class.render(pdf, data: nil)
        expect(pdf.page.content.stream.length).to eq(initial_stream_length)
      end
    end

    context 'when data is present' do
      it 'adds content to the PDF' do
        expect { described_class.render(pdf, data: valid_svg) }
          .to change { pdf.page.content.stream.length }
      end

      it 'creates bounding boxes for layout' do
        expect(pdf).to receive(:bounding_box).at_least(:once).and_call_original
        described_class.render(pdf, data: valid_svg)
      end

      it 'renders the SVG with correct parameters' do
        expect(pdf).to receive(:svg).with(
          anything,
          hash_including(position: :center)
        ).and_call_original

        described_class.render(pdf, data: valid_svg)
      end

      it 'sets up a background' do
        expect(pdf).to receive(:fill_rectangle).and_call_original
        described_class.render(pdf, data: valid_svg)
      end

      it 'successfully completes without errors' do
        expect { described_class.render(pdf, data: valid_svg) }
          .not_to raise_error
      end
    end

    context 'with different data formats' do
      it 'handles URL-encoded SVG strings' do
        expect { described_class.render(pdf, data: valid_svg) }
          .not_to raise_error
      end

      it 'handles hash with symbol key' do
        data = { svg: valid_svg }
        expect { described_class.render(pdf, data: data) }
          .not_to raise_error
      end

      it 'handles plain SVG strings' do
        plain_svg = '<svg><rect/></svg>'
        expect { described_class.render(pdf, data: plain_svg) }
          .not_to raise_error
      end
    end

    context 'with invalid data' do
      it 'returns :noop for empty string' do
        result = described_class.render(pdf, data: '')
        expect(result).to eq(:noop)
      end

      it 'returns :noop for non-SVG content' do
        result = described_class.render(pdf, data: '<div></div>')
        expect(result).to eq(:noop)
      end

      it 'returns :noop for hash with blank svg value' do
        result = described_class.render(pdf, data: { svg: '' })
        expect(result).to eq(:noop)
      end
    end
  end

  describe '#initialize' do
    it 'sets the pdf instance variable' do
      instance = described_class.new(pdf, valid_svg)
      expect(instance.instance_variable_get(:@pdf)).to eq(pdf)
    end

    it 'processes and stores the data' do
      instance = described_class.new(pdf, valid_svg)
      data = instance.instance_variable_get(:@data)
      expect(data).to be_present
      expect(data).to include('<svg')
    end

    context 'with nil data' do
      it 'sets data to nil' do
        instance = described_class.new(pdf, nil)
        expect(instance.instance_variable_get(:@data)).to be_nil
      end
    end
  end
end
