# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::Slack::Events::UrlVerification do
  describe '.call' do
    it 'returns the challenge' do
      expect(described_class.call({ challenge: 'foo' })).to eq({ challenge: 'foo' })
    end
  end
end
