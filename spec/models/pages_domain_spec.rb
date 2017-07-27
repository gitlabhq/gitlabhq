require 'spec_helper'

describe PagesDomain do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validate domain' do
    subject(:pages_domain) { build(:pages_domain, domain: domain) }

    context 'is unique' do
      let(:domain) { 'my.domain.com' }

      it { is_expected.to validate_uniqueness_of(:domain) }
    end

    {
      'my.domain.com'    => true,
      '123.456.789'      => true,
      '0x12345.com'      => true,
      '0123123'          => true,
      '_foo.com'         => false,
      'reserved.com'     => false,
      'a.reserved.com'   => false,
      nil                => false
    }.each do |value, validity|
      context "domain #{value.inspect} validity" do
        before do
          allow(Settings.pages).to receive(:host).and_return('reserved.com')
        end

        let(:domain) { value }

        it { expect(pages_domain.valid?).to eq(validity) }
      end
    end
  end

  describe 'validate certificate' do
    subject { domain }

    context 'when only certificate is specified' do
      let(:domain) { build(:pages_domain, :with_certificate) }

      it { is_expected.not_to be_valid }
    end

    context 'when only key is specified' do
      let(:domain) { build(:pages_domain, :with_key) }

      it { is_expected.not_to be_valid }
    end

    context 'with matching key' do
      let(:domain) { build(:pages_domain, :with_certificate, :with_key) }

      it { is_expected.to be_valid }
    end

    context 'for not matching key' do
      let(:domain) { build(:pages_domain, :with_missing_chain, :with_key) }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#url' do
    subject { domain.url }

    context 'without the certificate' do
      let(:domain) { build(:pages_domain) }

      it { is_expected.to eq('http://my.domain.com') }
    end

    context 'with a certificate' do
      let(:domain) { build(:pages_domain, :with_certificate) }

      it { is_expected.to eq('https://my.domain.com') }
    end
  end

  describe '#has_matching_key?' do
    subject { domain.has_matching_key? }

    context 'for matching key' do
      let(:domain) { build(:pages_domain, :with_certificate, :with_key) }

      it { is_expected.to be_truthy }
    end

    context 'for invalid key' do
      let(:domain) { build(:pages_domain, :with_missing_chain, :with_key) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_intermediates?' do
    subject { domain.has_intermediates? }

    context 'for self signed' do
      let(:domain) { build(:pages_domain, :with_certificate) }

      it { is_expected.to be_truthy }
    end

    context 'for missing certificate chain' do
      let(:domain) { build(:pages_domain, :with_missing_chain) }

      it { is_expected.to be_falsey }
    end

    context 'for trusted certificate chain' do
      # We only validate that we can to rebuild the trust chain, for certificates
      # We assume that 'AddTrustExternalCARoot' needed to validate the chain is in trusted store.
      # It will be if ca-certificates is installed on Debian/Ubuntu/Alpine

      let(:domain) { build(:pages_domain, :with_trusted_chain) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#expired?' do
    subject { domain.expired? }

    context 'for valid' do
      let(:domain) { build(:pages_domain, :with_certificate) }

      it { is_expected.to be_falsey }
    end

    context 'for expired' do
      let(:domain) { build(:pages_domain, :with_expired_certificate) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#subject' do
    let(:domain) { build(:pages_domain, :with_certificate) }

    subject { domain.subject }

    it { is_expected.to eq('/CN=test-certificate') }
  end

  describe '#certificate_text' do
    let(:domain) { build(:pages_domain, :with_certificate) }

    subject { domain.certificate_text }

    # We test only existence of output, since the output is long
    it { is_expected.not_to be_empty }
  end
end
