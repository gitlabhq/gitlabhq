require 'spec_helper'

describe PagesDomain do
  using RSpec::Parameterized::TableSyntax

  subject(:pages_domain) { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validate domain' do
    subject(:pages_domain) { build(:pages_domain, domain: domain) }

    context 'is unique' do
      let(:domain) { 'my.domain.com' }

      it { is_expected.to validate_uniqueness_of(:domain).case_insensitive }
    end

    describe "hostname" do
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

    describe "HTTPS-only" do
      using RSpec::Parameterized::TableSyntax

      let(:domain) { 'my.domain.com' }

      let(:project) do
        instance_double(Project, pages_https_only?: pages_https_only)
      end

      let(:pages_domain) do
        build(:pages_domain, certificate: certificate, key: key).tap do |pd|
          allow(pd).to receive(:project).and_return(project)
          pd.valid?
        end
      end

      where(:pages_https_only, :certificate, :key, :errors_on) do
        attributes = attributes_for(:pages_domain)
        cert, key = attributes.fetch_values(:certificate, :key)

        true  | nil  | nil | %i(certificate key)
        true  | cert | nil | %i(key)
        true  | nil  | key | %i(certificate key)
        true  | cert | key | []
        false | nil  | nil | []
        false | cert | nil | %i(key)
        false | nil  | key | %i(key)
        false | cert | key | []
      end

      with_them do
        it "is adds the expected errors" do
          expect(pages_domain.errors.keys).to eq errors_on
        end
      end
    end
  end

  describe 'validate certificate' do
    subject { domain }

    context 'with matching key' do
      let(:domain) { build(:pages_domain) }

      it { is_expected.to be_valid }
    end

    context 'when no certificate is specified' do
      let(:domain) { build(:pages_domain, :without_certificate) }

      it { is_expected.not_to be_valid }
    end

    context 'when no key is specified' do
      let(:domain) { build(:pages_domain, :without_key) }

      it { is_expected.not_to be_valid }
    end

    context 'for not matching key' do
      let(:domain) { build(:pages_domain, :with_missing_chain) }

      it { is_expected.not_to be_valid }
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:verification_code) }
  end

  describe '#verification_code' do
    subject { pages_domain.verification_code }

    it 'is set automatically with 128 bits of SecureRandom data' do
      expect(SecureRandom).to receive(:hex).with(16) { 'verification code' }

      is_expected.to eq('verification code')
    end
  end

  describe '#keyed_verification_code' do
    subject { pages_domain.keyed_verification_code }

    it { is_expected.to eq("gitlab-pages-verification-code=#{pages_domain.verification_code}") }
  end

  describe '#verification_domain' do
    subject { pages_domain.verification_domain }

    it { is_expected.to be_nil }

    it 'is a well-known subdomain if the domain is present' do
      pages_domain.domain = 'example.com'

      is_expected.to eq('_gitlab-pages-verification-code.example.com')
    end
  end

  describe '#url' do
    subject { domain.url }

    let(:domain) { build(:pages_domain) }

    it { is_expected.to eq("https://#{domain.domain}") }

    context 'without the certificate' do
      let(:domain) { build(:pages_domain, :without_certificate) }

      it { is_expected.to eq("http://#{domain.domain}") }
    end
  end

  describe '#has_matching_key?' do
    subject { domain.has_matching_key? }

    let(:domain) { build(:pages_domain) }

    it { is_expected.to be_truthy }

    context 'for invalid key' do
      let(:domain) { build(:pages_domain, :with_missing_chain) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_intermediates?' do
    subject { domain.has_intermediates? }

    context 'for self signed' do
      let(:domain) { build(:pages_domain) }

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
      let(:domain) { build(:pages_domain) }

      it { is_expected.to be_falsey }
    end

    context 'for expired' do
      let(:domain) { build(:pages_domain, :with_expired_certificate) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#subject' do
    let(:domain) { build(:pages_domain) }

    subject { domain.subject }

    it { is_expected.to eq('/CN=test-certificate') }
  end

  describe '#certificate_text' do
    let(:domain) { build(:pages_domain) }

    subject { domain.certificate_text }

    # We test only existence of output, since the output is long
    it { is_expected.not_to be_empty }
  end

  describe "#https?" do
    context "when a certificate is present" do
      subject { build(:pages_domain) }
      it { is_expected.to be_https }
    end

    context "when no certificate is present" do
      subject { build(:pages_domain, :without_certificate) }
      it { is_expected.not_to be_https }
    end
  end

  describe '#update_daemon' do
    it 'runs when the domain is created' do
      domain = build(:pages_domain)

      expect(domain).to receive(:update_daemon)

      domain.save!
    end

    it 'runs when the domain is destroyed' do
      domain = create(:pages_domain)

      expect(domain).to receive(:update_daemon)

      domain.destroy!
    end

    it 'delegates to Projects::UpdatePagesConfigurationService' do
      service = instance_double('Projects::UpdatePagesConfigurationService')
      expect(Projects::UpdatePagesConfigurationService).to receive(:new) { service }
      expect(service).to receive(:execute)

      create(:pages_domain)
    end

    context 'configuration updates when attributes change' do
      set(:project1) { create(:project) }
      set(:project2) { create(:project) }
      set(:domain) { create(:pages_domain) }

      where(:attribute, :old_value, :new_value, :update_expected) do
        now = Time.now
        future = now + 1.day

        :project | nil       | :project1 | true
        :project | :project1 | :project1 | false
        :project | :project1 | :project2 | true
        :project | :project1 | nil       | true

        # domain can't be set to nil
        :domain | 'a.com' | 'a.com' | false
        :domain | 'a.com' | 'b.com' | true

        # verification_code can't be set to nil
        :verification_code | 'foo' | 'foo'  | false
        :verification_code | 'foo' | 'bar'  | false

        :verified_at | nil | now    | false
        :verified_at | now | now    | false
        :verified_at | now | future | false
        :verified_at | now | nil    | false

        :enabled_until | nil | now    | true
        :enabled_until | now | now    | false
        :enabled_until | now | future | false
        :enabled_until | now | nil    | true
      end

      with_them do
        it 'runs if a relevant attribute has changed' do
          a = old_value.is_a?(Symbol) ? send(old_value) : old_value
          b = new_value.is_a?(Symbol) ? send(new_value) : new_value

          domain.update!(attribute => a)

          if update_expected
            expect(domain).to receive(:update_daemon)
          else
            expect(domain).not_to receive(:update_daemon)
          end

          domain.update!(attribute => b)
        end
      end

      context 'TLS configuration' do
        set(:domain_without_tls) { create(:pages_domain, :without_certificate, :without_key) }
        set(:domain) { create(:pages_domain) }

        let(:cert1) { domain.certificate }
        let(:cert2) { cert1 + ' ' }
        let(:key1) { domain.key }
        let(:key2) { key1 + ' ' }

        it 'updates when added' do
          expect(domain_without_tls).to receive(:update_daemon)

          domain_without_tls.update!(key: key1, certificate: cert1)
        end

        it 'updates when changed' do
          expect(domain).to receive(:update_daemon)

          domain.update!(key: key2, certificate: cert2)
        end

        it 'updates when removed' do
          expect(domain).to receive(:update_daemon)

          domain.update!(key: nil, certificate: nil)
        end
      end
    end
  end
end
