require 'spec_helper'

describe Gitlab::Badge::Build::Template do
  let(:status) { 'success' }
  let(:template) { described_class.new(status) }

  describe '#key_text' do
    it 'is always says build' do
      expect(template.key_text).to eq 'build'
    end
  end

  describe '#value_text' do
    it 'is status value' do
      expect(template.value_text).to eq 'success'
    end
  end

  describe 'widths and text anchors' do
    it 'has fixed width and text anchors' do
      expect(template.width).to eq 92
      expect(template.key_width).to eq 38
      expect(template.value_width).to eq 54
      expect(template.key_text_anchor).to eq 19
      expect(template.value_text_anchor).to eq 65
    end
  end

  describe '#key_color' do
    it 'is always the same' do
      expect(template.key_color).to eq '#555'
    end
  end

  describe '#value_color' do
    context 'when status is success' do
      let(:status) { 'success' }

      it 'has expected color' do
        expect(template.value_color).to eq '#4c1'
      end
    end

    context 'when status is failed' do
      let(:status) { 'failed' }

      it 'has expected color' do
        expect(template.value_color).to eq '#e05d44'
      end
    end

    context 'when status is running' do
      let(:status) { 'running' }

      it 'has expected color' do
        expect(template.value_color).to eq '#dfb317'
      end
    end

    context 'when status is unknown' do
      let(:status) { 'unknown' }

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end

    context 'when status does not match any known statuses' do
      let(:status) { 'invalid status' }

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end
  end
end
