# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PDF::Security::VulnerabilitiesByAge, feature_category: :vulnerability_management do
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
        _('Vulnerabilities by age'),
        anything
      ).and_call_original
      described_class.render(pdf, data: '<svg width="100" height="100"><rect/></svg>')
    end

    it 'renders the correct description' do
      allow(pdf).to receive(:text_box).and_call_original
      expect(pdf).to receive(:text_box).with(
        _('The number of vulnerabilities detected by age'),
        anything
      ).and_call_original
      described_class.render(pdf, data: '<svg width="100" height="100"><rect/></svg>')
    end
  end
end
