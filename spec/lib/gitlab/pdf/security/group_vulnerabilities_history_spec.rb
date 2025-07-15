# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::GroupVulnerabilitiesHistory, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }
  let(:mock_svg) do
    'data%3Aimage%2Fsvg+xml%3Bcharset%3DUTF-8%2C%3Csvg+width%3D%22357%22+height%3D%2232%22%3E%0A%3C%2Fsvg%3E'
  end

  let(:data) do
    {
      charts: [
        {
          svg: mock_svg,
          severity: "critical",
          current_count: 314,
          change_in_percent: "-"
        },
        {
          svg: mock_svg,
          severity: "high",
          current_count: 1148,
          change_in_percent: "-"
        },
        {
          svg: mock_svg,
          severity: "medium",
          current_count: 1587,
          change_in_percent: "-"
        },
        {
          svg: mock_svg,
          severity: "low",
          current_count: 150,
          change_in_percent: "-"
        }
      ],
      date_info: "May 18th to today",
      selected_day_range: 30
    }.with_indifferent_access
  end

  describe '.render' do
    subject(:render) { described_class.render(pdf, data: data) }

    let(:mock_instance) { instance_double(described_class) }

    before do
      allow(mock_instance).to receive(:render)
      allow(described_class).to receive(:new).and_return(mock_instance)
    end

    it 'creates a new instance and calls render on it' do
      render

      expect(described_class).to have_received(:new).with(pdf, data).once
      expect(mock_instance).to have_received(:render).exactly(:once)
    end
  end

  describe '#render' do
    subject(:render_chart) { described_class.render(pdf, data: data) }

    before do
      allow(pdf).to receive(:text_box).and_call_original
      allow(pdf).to receive(:svg).and_call_original
    end

    it 'includes expected text elements' do
      render_chart

      expect(pdf).to have_received(:text_box).with(s_('Vulnerability History'), any_args).once

      expected_date_string = "#{data[:date_info]} (#{data[:selected_day_range]} Days)"
      expect(pdf).to have_received(:text_box).with(expected_date_string, any_args).once

      expect(pdf).to have_received(:text_box).with('Critical', any_args).once
      expect(pdf).to have_received(:text_box).with('High', any_args).once
      expect(pdf).to have_received(:text_box).with('Medium', any_args).once
      expect(pdf).to have_received(:text_box).with('Low', any_args).once
    end

    it 'renders the SVG charts' do
      render_chart

      # 4 severity icons + 4 svg charts
      expect(pdf).to have_received(:svg).with(%r{<svg.*</svg>}, any_args).exactly(8).times
    end

    context 'when data is nil' do
      let(:data) { nil }

      it 'returns :noop without rendering anything' do
        expect(render_chart).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end

    context 'when data is blank' do
      let(:data) { {} }

      it 'returns :noop without rendering anything' do
        expect(render_chart).to eq(:noop)
        expect(pdf).not_to have_received(:svg)
        expect(pdf).not_to have_received(:text_box)
      end
    end
  end
end
