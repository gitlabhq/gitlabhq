# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationMailer, feature_category: :notifications do
  let(:mailer) { described_class.new }

  describe '#encode_display_name' do
    subject(:encode_display_name) { mailer.send(:encode_display_name, display_name) }

    context 'when name is nil' do
      let(:display_name) { nil }

      it { is_expected.to be_nil }
    end

    context 'when name is blank' do
      let(:display_name) { '' }

      it { is_expected.to eq('') }
    end

    context 'when name contains only ASCII characters' do
      let(:display_name) { 'John Doe' }

      it { is_expected.to eq('John Doe') }
    end

    context 'when name contains non-ASCII characters' do
      let(:display_name) { 'José García' }

      it { is_expected.to include('=?UTF-8?') }

      it 'decodes back to the original string' do
        expect(Mail::Encodings.value_decode(encode_display_name)).to eq('José García')
      end
    end

    context 'when name contains unicode characters' do
      let(:display_name) { 'Ünïcödé Tëst' }

      it { is_expected.to include('=?UTF-8?') }

      it 'decodes back to the original string' do
        expect(Mail::Encodings.value_decode(encode_display_name)).to eq('Ünïcödé Tëst')
      end
    end
  end
end
