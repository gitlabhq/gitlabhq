# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Pipeline::Template do
  let(:badge) { double(entity: 'pipeline', status: 'success', customization: {}) }
  let(:template) { described_class.new(badge) }

  it_behaves_like 'a badge template', 'pipeline'

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
        expect(template.value_color).to eq '#2da160'
      end
    end

    context 'when status is failed' do
      before do
        allow(badge).to receive(:status).and_return('failed')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#dd2b0e'
      end
    end

    context 'when status is canceled' do
      before do
        allow(badge).to receive(:status).and_return('canceled')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#737278'
      end
    end

    context 'when status is running' do
      before do
        allow(badge).to receive(:status).and_return('running')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#428fdc'
      end
    end

    context 'when status is preparing' do
      before do
        allow(badge).to receive(:status).and_return('preparing')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end

    context 'when status is waiting_for_resource' do
      before do
        allow(badge).to receive(:status).and_return('waiting_for_resource')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end

    context 'when status is created' do
      before do
        allow(badge).to receive(:status).and_return('created')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
      end
    end

    context 'when status is pending' do
      before do
        allow(badge).to receive(:status).and_return('pending')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#d99530'
      end
    end

    context 'when status is scheduled' do
      before do
        allow(badge).to receive(:status).and_return('scheduled')
      end

      it 'has expected color' do
        expect(template.value_color).to eq '#9f9f9f'
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
