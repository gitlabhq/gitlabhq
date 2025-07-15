# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::ProjectVulnerabilitiesHistory, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }
  let(:svg_data) do
    <<~SVG
      <svg width="1248" height="400" xmlns="http://www.w3.org/2000/svg">
        <rect width="1248" height="400" x="0" y="0" fill="none" fill-opacity="1"></rect>
        <path d="M64 319.5L1216 319.5" fill="none" stroke="var(--gl-chart-axis-line-color)"></path>
        <text dominant-baseline="central" text-anchor="middle" style="font-size:12px;font-family:sans-serif;font-weight:bold;" fill="var(--gl-text-color-default)">Vulnerabilities</text>
        <path d="M64 319L1216 319" fill="none" stroke="rgb(102,14,0)" stroke-width="2"></path>
        <path d="M64 319L1216 112.8" fill="none" stroke="rgb(174,24,0)" stroke-width="2"></path>
      </svg>
    SVG
  end

  describe '.render' do
    subject(:render) { described_class.render(pdf, data: svg_data) }

    let(:mock_instance) { instance_double(described_class) }

    before do
      allow(mock_instance).to receive(:render)
      allow(described_class).to receive(:new).and_return(mock_instance)
    end

    it 'creates a new instance and calls render on it' do
      render

      expect(described_class).to have_received(:new).with(pdf, svg_data).once
      expect(mock_instance).to have_received(:render).exactly(:once)
    end
  end

  describe '#render' do
    subject(:render_chart) { described_class.render(pdf, data: svg_data) }

    before do
      allow(pdf).to receive(:text_box).and_call_original
      allow(pdf).to receive(:svg).and_call_original
    end

    it 'include the chart title' do
      render_chart

      expect(pdf).to have_received(:text_box)
       .with('Vulnerability History', any_args).once

      # rubocop:disable Layout/LineLength -- long text for title
      expect(pdf).to have_received(:text_box)
       .with('Historical view of open vulnerabilities in the default branch. Excludes vulnerabilities that were resolved or dismissed.', any_args).once
      # rubocop:enable  Layout/LineLength
    end

    it 'renders the SVG chart' do
      render_chart

      expect(pdf).to have_received(:svg).with(%r{<svg.*</svg>}, any_args)
    end

    it 'renders the chart legend' do
      render_chart

      %w[Critical High Medium Low Info Unknown].each do |severity|
        expect(pdf).to have_received(:text_box).with(severity, any_args)
      end
    end

    context 'when svg data is nil' do
      let(:svg_data) { nil }

      it 'returns :noop without rendering anything' do
        expect(render_chart).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end

    context 'when svg data is blank' do
      let(:svg_data) { '' }

      it 'returns :noop without rendering anything' do
        expect(render_chart).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end
  end
end
