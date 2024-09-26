# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::SentryClient::Token, feature_category: :observability do
  describe '.masked_token?' do
    subject { described_class.masked_token?(token) }

    context 'with masked token' do
      let(:token) { '*********' }

      it { is_expected.to be_truthy }
    end

    context 'without masked token' do
      let(:token) { 'token' }

      it { is_expected.to be_falsey }
    end
  end
end
