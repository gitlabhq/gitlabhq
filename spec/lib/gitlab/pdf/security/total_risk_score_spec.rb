# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::TotalRiskScore, feature_category: :vulnerability_management do
  let(:pdf) { Prawn::Document.new }

  describe 'constants' do
    it 'has a TOTAL_HEIGHT of 250' do
      expect(described_class::TOTAL_HEIGHT).to eq(250)
    end
  end

  describe '#render' do
    it 'renders the correct title' do
      allow(pdf).to receive(:text_box).and_call_original
      expect(pdf).to receive(:text_box).with(
        _('Total Risk Score'),
        anything
      ).and_call_original
      described_class.render(pdf, data: '<svg width="100" height="100"><rect/></svg>')
    end

    it 'renders the correct description' do
      allow(pdf).to receive(:text_box).and_call_original
      expect(pdf).to receive(:text_box).with(
        _('The overall risk score for your organization based on vulnerability severity and age.'),
        anything
      ).and_call_original
      described_class.render(pdf, data: '<svg width="100" height="100"><rect/></svg>')
    end

    it 'substitutes CSS variables with hardcoded colors' do
      css_variables = described_class::CSS_TRANSLATIONS.map(&:first)
      svg = "<svg width=\"100\" height=\"100\"><path stroke=\"#{css_variables.first}\"/></svg>"

      instance = described_class.new(pdf, svg)
      data = instance.instance_variable_get(:@data)

      css_variables.each do |variable|
        expect(data).not_to include(variable)
      end
    end
  end
end
