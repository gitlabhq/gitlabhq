# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::GroupVulnerabilitiesHistory, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }
  # rubocop:disable Layout/LineLength -- data strings
  let(:data) do
    {
      charts: [
        {
          svg: "data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%22357%22%20height%3D%2232%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20viewBox%3D%220%200%20357%2032%22%3E%0A%3Crect%20width%3D%22357%22%20height%3D%2232%22%20x%3D%220%22%20y%3D%220%22%20id%3D%220%22%20fill%3D%22none%22%20fill-opacity%3D%221%22%3E%3C%2Frect%3E%0A%3Cg%20clip-path%3D%22url(%23zr8-c0)%22%3E%0A%3Cpath%20d%3D%22M3%2029L14.7%2029L26.4%2029L38.1%2029L49.8%2029L61.5%2029L73.2%2029L84.9%2029L96.6%2029L108.3%2029L120%2029L131.7%2029L143.4%2029L155.1%2029L166.8%2029L178.5%2029L190.2%2029L201.9%2029L213.6%2029L225.3%2029L237%2029L248.7%2029L260.4%2029L272.1%2029L283.8%205.6743L295.5%205.6743L307.2%205.6743L318.9%205.6743L330.6%205.6743L342.3%205.6743L354%205.6743%22%20fill%3D%22none%22%20stroke%3D%22rgb(97%2C122%2C226)%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22bevel%22%3E%3C%2Fpath%3E%0A%3C%2Fg%3E%0A%3Cdefs%20%3E%0A%3CclipPath%20id%3D%22zr8-c0%22%3E%0A%3Cpath%20d%3D%22M2%202l353%200l0%2028l-353%200Z%22%20fill%3D%22%23000%22%3E%3C%2Fpath%3E%0A%3C%2FclipPath%3E%0A%3C%2Fdefs%3E%0A%3C%2Fsvg%3E",
          severity: "critical",
          current_count: 314,
          change_in_percent: "-"
        },
        {
          svg: "data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%22357%22%20height%3D%2232%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20viewBox%3D%220%200%20357%2032%22%3E%0A%3Crect%20width%3D%22357%22%20height%3D%2232%22%20x%3D%220%22%20y%3D%220%22%20id%3D%220%22%20fill%3D%22none%22%20fill-opacity%3D%221%22%3E%3C%2Frect%3E%0A%3Cg%20clip-path%3D%22url(%23zr9-c0)%22%3E%0A%3Cpath%20d%3D%22M3%2029L14.7%2029L26.4%2029L38.1%2029L49.8%2029L61.5%2028.74L73.2%2028.74L84.9%2028.74L96.6%2028.74L108.3%2028.74L120%2028.74L131.7%2028.74L143.4%2028.74L155.1%2028.74L166.8%2028.74L178.5%2028.74L190.2%2028.74L201.9%2028.74L213.6%2028.74L225.3%2028.74L237%2028.74L248.7%2028.74L260.4%2028.74L272.1%2028.74L283.8%204.1267L295.5%204.1267L307.2%204.1267L318.9%204.1267L330.6%204.1267L342.3%204.1267L354%204.1267%22%20fill%3D%22none%22%20stroke%3D%22rgb(97%2C122%2C226)%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22bevel%22%3E%3C%2Fpath%3E%0A%3C%2Fg%3E%0A%3Cdefs%20%3E%0A%3CclipPath%20id%3D%22zr9-c0%22%3E%0A%3Cpath%20d%3D%22M2%202l353%200l0%2028l-353%200Z%22%20fill%3D%22%23000%22%3E%3C%2Fpath%3E%0A%3C%2FclipPath%3E%0A%3C%2Fdefs%3E%0A%3C%2Fsvg%3E",
          severity: "high",
          current_count: 1148,
          change_in_percent: "-"
        },
        {
          svg: "data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%22357%22%20height%3D%2232%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20viewBox%3D%220%200%20357%2032%22%3E%0A%3Crect%20width%3D%22357%22%20height%3D%2232%22%20x%3D%220%22%20y%3D%220%22%20id%3D%220%22%20fill%3D%22none%22%20fill-opacity%3D%221%22%3E%3C%2Frect%3E%0A%3Cg%20clip-path%3D%22url(%23zr10-c0)%22%3E%0A%3Cpath%20d%3D%22M3%2029L14.7%2029L26.4%2029L38.1%2029L49.8%2029L61.5%2027.2811L73.2%2027.2811L84.9%2027.2811L96.6%2027.2811L108.3%2027.2811L120%2027.2811L131.7%2027.2811L143.4%2027.2811L155.1%2027.2811L166.8%2027.2811L178.5%2027.2811L190.2%2027.2811L201.9%2027.2811L213.6%2027.2811L225.3%2027.2811L237%2027.2811L248.7%2027.2811L260.4%2027.2811L272.1%2027.2811L283.8%206.0767L295.5%206.0767L307.2%206.0767L318.9%206.0767L330.6%206.0767L342.3%206.0767L354%206.0767%22%20fill%3D%22none%22%20stroke%3D%22rgb(97%2C122%2C226)%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22bevel%22%3E%3C%2Fpath%3E%0A%3C%2Fg%3E%0A%3Cdefs%20%3E%0A%3CclipPath%20id%3D%22zr10-c0%22%3E%0A%3Cpath%20d%3D%22M2%202l353%200l0%2028l-353%200Z%22%20fill%3D%22%23000%22%3E%3C%2Fpath%3E%0A%3C%2FclipPath%3E%0A%3C%2Fdefs%3E%0A%3C%2Fsvg%3E",
          severity: "medium",
          current_count: 1587,
          change_in_percent: "-"
        },
        {
          svg: "data:image/svg+xml;charset=UTF-8,%3Csvg%20width%3D%22357%22%20height%3D%2232%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20xmlns%3Axlink%3D%22http%3A%2F%2Fwww.w3.org%2F1999%2Fxlink%22%20version%3D%221.1%22%20baseProfile%3D%22full%22%20viewBox%3D%220%200%20357%2032%22%3E%0A%3Crect%20width%3D%22357%22%20height%3D%2232%22%20x%3D%220%22%20y%3D%220%22%20id%3D%220%22%20fill%3D%22none%22%20fill-opacity%3D%221%22%3E%3C%2Frect%3E%0A%3Cg%20clip-path%3D%22url(%23zr11-c0)%22%3E%0A%3Cpath%20d%3D%22M3%2029L14.7%2029L26.4%2029L38.1%2029L49.8%2029L61.5%2027.96L73.2%2027.96L84.9%2027.96L96.6%2027.96L108.3%2027.96L120%2027.96L131.7%2027.96L143.4%2027.96L155.1%2027.96L166.8%2027.96L178.5%2027.96L190.2%2027.96L201.9%2027.96L213.6%2027.96L225.3%2027.96L237%2027.96L248.7%2027.96L260.4%2027.96L272.1%2027.96L283.8%203L295.5%203L307.2%203L318.9%203L330.6%203L342.3%203L354%203%22%20fill%3D%22none%22%20stroke%3D%22rgb(97%2C122%2C226)%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22bevel%22%3E%3C%2Fpath%3E%0A%3C%2Fg%3E%0A%3Cdefs%20%3E%0A%3CclipPath%20id%3D%22zr11-c0%22%3E%0A%3Cpath%20d%3D%22M2%202l353%200l0%2028l-353%200Z%22%20fill%3D%22%23000%22%3E%3C%2Fpath%3E%0A%3C%2FclipPath%3E%0A%3C%2Fdefs%3E%0A%3C%2Fsvg%3E",
          severity: "low",
          current_count: 150,
          change_in_percent: "-"
        }
      ],
      date_info: "May 18th to today",
      selected_day_range: 30
    }.with_indifferent_access
  end
  # rubocop:enable Layout/LineLength

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

      expected_date_string = "#{data[:date_info]} (#{data[:selected_day_range]})"
      expect(pdf).to have_received(:text_box).with(expected_date_string, any_args).once

      expect(pdf).to have_received(:text_box).with('critical', any_args).once
      expect(pdf).to have_received(:text_box).with('high', any_args).once
      expect(pdf).to have_received(:text_box).with('medium', any_args).once
      expect(pdf).to have_received(:text_box).with('low', any_args).once
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
