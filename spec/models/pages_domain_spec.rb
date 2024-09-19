# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesDomain, feature_category: :pages do
  using RSpec::Parameterized::TableSyntax

  subject(:pages_domain) { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe '.for_project' do
    it 'returns domains assigned to project' do
      domain = create(:pages_domain)
      create(:pages_domain) # unrelated domain

      expect(described_class.for_project(domain.project)).to eq([domain])
    end
  end

  describe '.verified' do
    let!(:verified) { create(:pages_domain) }
    let!(:unverified) { create(:pages_domain, :unverified) }

    it 'finds verified' do
      expect(described_class.verified).to match_array(verified)
    end
  end

  describe 'domain validations' do
    subject(:pages_domain) { build(:pages_domain, domain: domain) }

    context 'when the domain is unique' do
      let(:domain) { 'my.domain.com' }

      it { is_expected.to validate_uniqueness_of(:domain).case_insensitive }
    end

    context "with different domain names" do
      before do
        allow(Settings.pages).to receive(:host).and_return('reserved.com')
      end

      where(:domain, :expected) do
        'my.domain.com'    | true
        '123.456.789'      | true
        '0x12345.com'      | true
        '0123123'          | true
        'a-reserved.com'   | true
        'a.b-reserved.com' | true
        'reserved.com'     | true

        '_foo.com'         | false
        'a.reserved.com'   | false
        'a.b.reserved.com' | false
        nil                | false
      end

      with_them do
        it { is_expected.to have_attributes(valid?: expected) }
      end
    end

    describe "HTTPS-only" do
      let(:domain) { 'my.domain.com' }

      let(:pages_domain) do
        build(:pages_domain, certificate: certificate, key: key, auto_ssl_enabled: auto_ssl_enabled)
      end

      before do
        allow(pages_domain.project)
          .to receive(:can_create_custom_domains?)
                .and_return(true)
      end

      context 'when project is set to use pages https only' do
        before do
          allow(pages_domain.project)
            .to receive(:pages_https_only?)
                  .and_return(true)
        end

        where(:certificate, :key, :auto_ssl_enabled, :errors_on) do
          attributes = attributes_for(:pages_domain)
          cert, key = attributes.fetch_values(:certificate, :key)

          nil  | nil | false | %i[certificate key]
          nil  | nil | true  | []
          cert | nil | false | %i[key]
          cert | nil | true  | %i[key]
          nil  | key | false | %i[certificate key]
          nil  | key | true  | %i[key]
          cert | key | false | []
          cert | key | true  | []
        end

        with_them do
          it "is adds the expected errors" do
            pages_domain.valid?

            expect(pages_domain.errors.attribute_names).to eq errors_on
          end
        end
      end

      context 'when project is not set to https only' do
        where(:certificate, :key, :auto_ssl_enabled, :errors_on) do
          attributes = attributes_for(:pages_domain)
          cert, key = attributes.fetch_values(:certificate, :key)

          nil  | nil | false | []
          nil  | nil | true  | []
          cert | nil | false | %i[key]
          cert | nil | true  | %i[key]
          nil  | key | false | %i[key]
          nil  | key | true  | %i[key]
          cert | key | false | []
          cert | key | true  | []
        end

        with_them do
          it "is adds the expected errors" do
            pages_domain.valid?

            expect(pages_domain.errors.attribute_names).to eq errors_on
          end
        end
      end
    end
  end

  describe 'when certificate is specified' do
    let(:domain) { build(:pages_domain) }

    it 'saves validity time' do
      domain.save!

      expect(domain.certificate_valid_not_before).to be_like_time(Time.zone.parse("2020-03-16 14:20:34 UTC"))
      expect(domain.certificate_valid_not_after).to be_like_time(Time.zone.parse("2220-01-28 14:20:34 UTC"))
    end
  end

  describe 'validate certificate' do
    subject { domain }

    context 'for serverless domain' do
      it 'requires certificate and key to be present' do
        expect(build(:pages_domain, :without_certificate, :without_key, usage: :serverless)).not_to be_valid
        expect(build(:pages_domain, :without_certificate, usage: :serverless)).not_to be_valid
        expect(build(:pages_domain, :without_key, usage: :serverless)).not_to be_valid
      end
    end

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

    context 'when certificate is expired' do
      let(:domain) { build(:pages_domain, :with_trusted_expired_chain) }

      context 'when certificate is being changed' do
        it "adds error to certificate" do
          domain.valid?

          expect(domain.errors.attribute_names).to contain_exactly(:key)
        end
      end

      context 'when certificate is already saved' do
        it "doesn't add error to certificate" do
          domain.save!(validate: false)

          domain.valid?

          expect(domain.errors.attribute_names).to contain_exactly(:key)
        end
      end
    end

    context 'with ecdsa certificate' do
      let(:domain) { build(:pages_domain, :ecdsa) }

      it { is_expected.to be_valid }

      context 'when curve is set explicitly by parameters' do
        let(:domain) { build(:pages_domain, :explicit_ecdsa) }

        it 'adds errors to private key' do
          is_expected.to be_invalid

          expect(domain.errors[:key]).to be_present
        end
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:verification_code) }

    context 'when validating max certificate key length' do
      it 'validates the certificate key length' do
        valid_domain = build(:pages_domain, :key_length_8192)
        expect(valid_domain).to be_valid
      end

      context 'when the key has more than 8192 bytes' do
        let(:domain) do
          build(:pages_domain, :extra_long_key)
        end

        it 'adds a human readable error' do
          expect(domain).to be_invalid
          expect(domain.errors[:key]).to include('Certificate Key is too long. (Max 8192 bytes)')
        end

        it 'does not run SSL key verification' do
          allow(domain).to receive(:validate_intermediates)

          domain.valid?

          expect(domain).not_to have_received(:validate_intermediates)
        end
      end
    end
  end

  describe 'default values' do
    it do
      is_expected.to have_attributes(
        wildcard: false,
        auto_ssl_enabled: false,
        scope: 'project',
        usage: 'pages'
      )
    end
  end

  describe '#verification_code' do
    subject { pages_domain.verification_code }

    it 'is set automatically with 128 bits of SecureRandom data' do
      expect(SecureRandom).to receive(:hex).with(16).and_return('verification code')

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

  describe '#has_valid_intermediates?' do
    subject { domain.has_valid_intermediates? }

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

    context 'for chain with unknown root CA' do
      # In cases where users use an origin certificate the CA does not necessarily need to be in
      # the trust store, eg. in the case of Cloudflare Origin Certs.
      let(:domain) { build(:pages_domain, :with_untrusted_root_ca_in_chain) }

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

  describe '#user_provided_key' do
    subject { domain.user_provided_key }

    context 'when certificate is provided by user' do
      let(:domain) { create(:pages_domain) }

      it { is_expected.to eq domain.key }
    end

    context 'when certificate is provided by gitlab' do
      let(:domain) { create(:pages_domain, :letsencrypt) }

      it { is_expected.to be_nil }
    end
  end

  describe '#user_provided_certificate' do
    subject { domain.user_provided_certificate }

    context 'when certificate is provided by user' do
      let(:domain) { create(:pages_domain) }

      it { is_expected.to eq domain.certificate }
    end

    context 'when certificate is provided by gitlab' do
      let(:domain) { create(:pages_domain, :letsencrypt) }

      it { is_expected.to be_nil }
    end
  end

  shared_examples 'certificate setter' do |attribute, setter_name, old_certificate_source, new_certificate_source|
    let(:domain) { create(:pages_domain, certificate_source: old_certificate_source) }

    let(:old_value) { domain.public_send(attribute) }

    subject { domain.public_send(setter_name, new_value) }

    context 'when value has been changed' do
      let(:new_value) { 'new_value' }

      it "assignes new value to #{attribute}" do
        expect { subject }
          .to change { domain.public_send(attribute) }.from(old_value).to('new_value')
      end

      it 'changes certificate source' do
        expect { subject }
          .to change { domain.certificate_source }.from(old_certificate_source).to(new_certificate_source)
      end
    end

    context 'when value has not been not changed' do
      let(:new_value) { old_value }

      it 'does not change certificate source' do
        expect do
          subject
        end.not_to change { domain.certificate_source }.from(old_certificate_source)
      end
    end
  end

  describe '#user_provided_key=' do
    include_examples(
      'certificate setter', 'key', 'user_provided_key=', 'gitlab_provided', 'user_provided'
    )
  end

  describe '#gitlab_provided_key=' do
    include_examples(
      'certificate setter', 'key', 'gitlab_provided_key=', 'user_provided', 'gitlab_provided'
    )
  end

  describe '#user_provided_certificate=' do
    include_examples(
      'certificate setter', 'certificate', 'user_provided_certificate=', 'gitlab_provided', 'user_provided'
    )
  end

  describe '#gitlab_provided_certificate=' do
    include_examples(
      'certificate setter', 'certificate', 'gitlab_provided_certificate=', 'user_provided', 'gitlab_provided'
    )
  end

  describe '#save' do
    context 'when we failed to obtain ssl certificate' do
      let(:domain) { create(:pages_domain, auto_ssl_enabled: true, auto_ssl_failed: true) }

      it 'clears failure if auto ssl is disabled' do
        expect { domain.update!(auto_ssl_enabled: false) }.to change { domain.auto_ssl_failed }.from(true).to(false)
      end

      it 'does not clear failure on unrelated updates' do
        expect { domain.update!(verified_at: Time.current) }.not_to change { domain.auto_ssl_failed }.from(true)
      end
    end
  end

  describe '.for_removal' do
    subject { described_class.for_removal }

    context 'when domain is not schedule for removal' do
      let!(:domain) { create :pages_domain }

      it 'does not return domain' do
        is_expected.to be_empty
      end
    end

    context 'when domain is scheduled for removal yesterday' do
      let!(:domain) { create :pages_domain, remove_at: 1.day.ago }

      it 'returns domain' do
        is_expected.to eq([domain])
      end
    end

    context 'when domain is scheduled for removal tomorrow' do
      let!(:domain) { create :pages_domain, remove_at: 1.day.from_now }

      it 'does not return domain' do
        is_expected.to be_empty
      end
    end
  end

  describe '.instance_serverless' do
    let_it_be(:domain_1) { create(:pages_domain, wildcard: true) }
    let_it_be(:domain_2) { create(:pages_domain, :instance_serverless) }
    let_it_be(:domain_3) { create(:pages_domain, scope: :instance) }
    let_it_be(:domain_4) { create(:pages_domain, :instance_serverless) }
    let_it_be(:domain_5) { create(:pages_domain, usage: :serverless) }

    subject { described_class.instance_serverless }

    it 'returns domains that are wildcard, instance-level, and serverless' do
      is_expected.to match_array [domain_2, domain_4]
    end
  end

  describe '.need_auto_ssl_renewal' do
    subject { described_class.need_auto_ssl_renewal }

    let!(:domain_with_user_provided_certificate) { create(:pages_domain) }
    let!(:domain_with_expired_user_provided_certificate) do
      create(:pages_domain, :with_expired_certificate)
    end

    let!(:domain_with_user_provided_certificate_and_auto_ssl) do
      create(:pages_domain, auto_ssl_enabled: true)
    end

    let!(:domain_with_gitlab_provided_certificate) { create(:pages_domain, :letsencrypt) }
    let!(:domain_with_expired_gitlab_provided_certificate) do
      create(:pages_domain, :letsencrypt, :with_expired_certificate)
    end

    let!(:domain_with_failed_auto_ssl) do
      create(:pages_domain, auto_ssl_enabled: true, auto_ssl_failed: true)
    end

    it 'contains only domains needing ssl renewal' do
      is_expected.to(
        contain_exactly(
          domain_with_user_provided_certificate_and_auto_ssl,
          domain_with_expired_gitlab_provided_certificate
        )
      )
    end
  end

  describe '#validate_custom_domain_count_per_project' do
    let_it_be(:project) { create(:project) }

    context 'when max custom domain setting is set to 0' do
      it 'returns without an error' do
        pages_domain = create(:pages_domain, project: project)

        expect(pages_domain).to be_valid
      end
    end

    context 'when max custom domain setting is not set to 0' do
      it 'returns with an error for extra domains' do
        Gitlab::CurrentSettings.update!(max_pages_custom_domains_per_project: 1)

        pages_domain = create(:pages_domain, project: project)
        expect(pages_domain).to be_valid

        pages_domain = build(:pages_domain, project: project)
        expect(pages_domain).not_to be_valid
        expect(pages_domain.errors.full_messages)
          .to contain_exactly('This project reached the limit of custom domains. (Max 1)')
      end
    end
  end

  describe '.find_by_domain_case_insensitive' do
    let_it_be(:pages_domain) { create(:pages_domain, domain: "Pages.IO") }

    it 'lookup is case-insensitive' do
      expect(described_class.find_by_domain_case_insensitive('pages.io')).to eq pages_domain
    end
  end
end
