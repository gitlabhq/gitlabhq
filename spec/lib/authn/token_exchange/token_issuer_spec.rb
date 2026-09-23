# frozen_string_literal: true

require 'spec_helper'

# The EE override supplies the signing key, so these defaults only hold in FOSS.
RSpec.describe Authn::TokenExchange::TokenIssuer, unless: Gitlab.ee?, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  subject(:issuer) do
    described_class.new(audiences: ['gitlab-iam-data-access'], user: user, organization: user.organization)
  end

  describe '.available?' do
    it 'is false without a signing key' do
      expect(described_class.available?).to be(false)
    end
  end

  describe '#token' do
    it 'raises because no edition-provided signing key exists' do
      expect { issuer.token }.to raise_error(Gitlab::AbstractMethodError)
    end
  end
end
