require 'spec_helper'

describe Gitlab::Badge::Pipeline::Template do
  let(:badge) { double(entity: 'pipeline', status: 'success') }
  let(:template) { described_class.new(badge) }

  describe '#key_text' do
    it 'is always says pipeline' do
      expect(template.key_text).to eq 'pipeline'
    end
  end

  describe '#value_text' do
    it 'is status value' do
      expect(template.value_text).to eq 'passed'
    end
  end

  describe 'widths and text anchors' do
    it 'has fixed width and text anchors' do
      expect(template.width).to eq 116
      expect(template.key_width).to eq 62
      expect(template.value_width).to eq 54
      expect(template.key_text_anchor).to eq 31
      expect(template.value_text_anchor).to eq 89
    end
  end

  describe '#key_color' do
    it 'is always the same' do
      expect(template.key_color).to eq '#555'
    end
  end

  describe '#value_color' do
    context 'when status is success' do
      it 'has expected color' do
        expect(template.value_color).to eq '#4c1'
      end
    end

    context 'when status is failed' do
      before do
        allow(badge).to receive(:status).and_return('failed')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#e05d44'
      end
    end

    context 'when status is running' do
      before do
        allow(badge).to receive(:status).and_return('running')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#dfb317'
      end
    end

    context 'when status is unknown' do
      before do
        allow(badge).to receive(:status).and_return('unknown')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end

    context 'when status does not match any known statuses' do
      before do
        allow(badge).to receive(:status).and_return('invalid')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end
  end
end
