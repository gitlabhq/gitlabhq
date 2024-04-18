# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrors::Attributes, feature_category: :source_code_management do
  subject(:attributes) { described_class.new(attrs) }

  let(:attrs) do
    {
      url: 'https://example.com',
      enabled: true
    }
  end

  describe '#allowed' do
    subject { attributes.allowed }

    it { is_expected.to eq(attrs) }

    context 'when an unsupported attribute is provided' do
      let(:attrs) { super().merge(unknown: :attribute) }

      it 'returns only allowed attributes' do
        is_expected.to eq(url: 'https://example.com', enabled: true)
      end
    end
  end

  describe '#keys' do
    subject { attributes.keys }

    it 'returns a list of allowed keys' do
      is_expected.to include(*described_class::ALLOWED_ATTRIBUTES)
    end
  end
end
