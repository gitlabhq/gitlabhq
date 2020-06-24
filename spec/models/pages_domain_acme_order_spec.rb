# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomainAcmeOrder do
  using RSpec::Parameterized::TableSyntax

  describe '.expired' do
    let!(:not_expired_order) { create(:pages_domain_acme_order) }
    let!(:expired_order) { create(:pages_domain_acme_order, :expired) }

    it 'returns only expired orders' do
      expect(described_class.count).to eq(2)
      expect(described_class.expired).to eq([expired_order])
    end
  end

  describe '.find_by_domain_and_token' do
    let!(:domain) { create(:pages_domain, domain: 'test.com') }
    let!(:acme_order) { create(:pages_domain_acme_order, challenge_token: 'righttoken', pages_domain: domain) }

    where(:domain_name, :challenge_token, :present) do
      'test.com' | 'righttoken' | true
      'test.com' | 'wrongtoken' | false
      'test.org' | 'righttoken' | false
    end

    with_them do
      subject { described_class.find_by_domain_and_token(domain_name, challenge_token).present? }

      it { is_expected.to eq(present) }
    end
  end

  subject { create(:pages_domain_acme_order) }

  describe 'associations' do
    it { is_expected.to belong_to(:pages_domain) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:pages_domain) }
    it { is_expected.to validate_presence_of(:expires_at) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:challenge_token) }
    it { is_expected.to validate_presence_of(:challenge_file_content) }
    it { is_expected.to validate_presence_of(:private_key) }
  end
end
