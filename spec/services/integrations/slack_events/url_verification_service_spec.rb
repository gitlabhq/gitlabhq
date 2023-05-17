# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEvents::UrlVerificationService, feature_category: :integrations do
  describe '#execute' do
    it 'returns the challenge' do
      expect(described_class.new({ challenge: 'foo' }).execute).to eq({ challenge: 'foo' })
    end
  end
end
