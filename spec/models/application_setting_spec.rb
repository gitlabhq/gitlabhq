# frozen_string_literal: true

require 'spec_helper'

describe ApplicationSetting do
  using RSpec::Parameterized::TableSyntax

  subject(:setting) { described_class.create_from_defaults }

  it { include(CacheableAttributes) }
  it { include(ApplicationSettingImplementation) }
  it { expect(described_class.current_without_cache).to eq(described_class.last) }

  it { expect(setting).to be_valid }
  it { expect(setting.uuid).to be_present }
  it { expect(setting).to have_db_column(:auto_devops_enabled) }

  context "with existing plaintext attributes" do
    before do
      setting.update_columns(
        akismet_api_key: "akismet_api_key",
        elasticsearch_aws_secret_access_key: "elasticsearch_aws_secret_access_key",
        recaptcha_private_key: "recaptcha_private_key",
        recaptcha_site_key: "recaptcha_site_key",
        slack_app_secret: "slack_app_secret",
        slack_app_verification_token: "slack_app_verification_token"
      )
    end

    it "returns the attributes" do
      expect(setting.akismet_api_key).to eq("akismet_api_key")
      expect(setting.elasticsearch_aws_secret_access_key).to eq("elasticsearch_aws_secret_access_key")
      expect(setting.recaptcha_private_key).to eq("recaptcha_private_key")
      expect(setting.recaptcha_site_key).to eq("recaptcha_site_key")
      expect(setting.slack_app_secret).to eq("slack_app_secret")
      expect(setting.slack_app_verification_token).to eq("slack_app_verification_token")
    end
  end

  context "with encrypted attributes" do
    before do
      setting.update(
        akismet_api_key: "akismet_api_key",
        elasticsearch_aws_secret_access_key: "elasticsearch_aws_secret_access_key",
        recaptcha_private_key: "recaptcha_private_key",
        recaptcha_site_key: "recaptcha_site_key",
        slack_app_secret: "slack_app_secret",
        slack_app_verification_token: "slack_app_verification_token"
      )
    end

    it "returns the attributes" do
      expect(setting.akismet_api_key).to eq("akismet_api_key")
      expect(setting.elasticsearch_aws_secret_access_key).to eq("elasticsearch_aws_secret_access_key")
      expect(setting.recaptcha_private_key).to eq("recaptcha_private_key")
      expect(setting.recaptcha_site_key).to eq("recaptcha_site_key")
      expect(setting.slack_app_secret).to eq("slack_app_secret")
      expect(setting.slack_app_verification_token).to eq("slack_app_verification_token")
    end
  end

  describe 'validations' do
    let(:http)  { 'http://example.com' }
    let(:https) { 'https://example.com' }
    let(:ftp)   { 'ftp://example.com' }

    it { is_expected.to allow_value(nil).for(:home_page_url) }
    it { is_expected.to allow_value(http).for(:home_page_url) }
    it { is_expected.to allow_value(https).for(:home_page_url) }
    it { is_expected.not_to allow_value(ftp).for(:home_page_url) }

    it { is_expected.to allow_value(nil).for(:after_sign_out_path) }
    it { is_expected.to allow_value(http).for(:after_sign_out_path) }
    it { is_expected.to allow_value(https).for(:after_sign_out_path) }
    it { is_expected.not_to allow_value(ftp).for(:after_sign_out_path) }

    it { is_expected.to allow_value("dev.gitlab.com").for(:commit_email_hostname) }
    it { is_expected.not_to allow_value("@dev.gitlab").for(:commit_email_hostname) }

    it { is_expected.to allow_value("myemail@gitlab.com").for(:lets_encrypt_notification_email) }
    it { is_expected.to allow_value(nil).for(:lets_encrypt_notification_email) }
    it { is_expected.not_to allow_value("notanemail").for(:lets_encrypt_notification_email) }
    it { is_expected.not_to allow_value("myemail@example.com").for(:lets_encrypt_notification_email) }
    it { is_expected.to allow_value("myemail@test.example.com").for(:lets_encrypt_notification_email) }

    it { is_expected.to allow_value(['192.168.1.1'] * 1_000).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['192.168.1.1'] * 1_001).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['1' * 255]).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['1' * 256]).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['ğitlab.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['xn--itlab-j1a.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(['<h1></h1>']).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value(['gitlab.com']).for(:outbound_local_requests_whitelist) }
    it { is_expected.not_to allow_value(nil).for(:outbound_local_requests_whitelist) }
    it { is_expected.to allow_value([]).for(:outbound_local_requests_whitelist) }

    it { is_expected.to allow_value(nil).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(http).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(https).for(:static_objects_external_storage_url) }
    it { is_expected.to allow_value(['/example'] * 100).for(:protected_paths) }
    it { is_expected.not_to allow_value(['/example'] * 101).for(:protected_paths) }
    it { is_expected.not_to allow_value(nil).for(:protected_paths) }
    it { is_expected.to allow_value([]).for(:protected_paths) }

    it { is_expected.to allow_value(3).for(:push_event_hooks_limit) }
    it { is_expected.not_to allow_value('three').for(:push_event_hooks_limit) }
    it { is_expected.not_to allow_value(nil).for(:push_event_hooks_limit) }

    it { is_expected.to allow_value(3).for(:push_event_activities_limit) }
    it { is_expected.not_to allow_value('three').for(:push_event_activities_limit) }
    it { is_expected.not_to allow_value(nil).for(:push_event_activities_limit) }

    context 'when snowplow is enabled' do
      before do
        setting.snowplow_enabled = true
      end

      it { is_expected.not_to allow_value(nil).for(:snowplow_collector_hostname) }
      it { is_expected.to allow_value("snowplow.gitlab.com").for(:snowplow_collector_hostname) }
      it { is_expected.not_to allow_value('/example').for(:snowplow_collector_hostname) }
      it { is_expected.to allow_value('https://example.org').for(:snowplow_iglu_registry_url) }
      it { is_expected.not_to allow_value('not-a-url').for(:snowplow_iglu_registry_url) }
      it { is_expected.to allow_value(nil).for(:snowplow_iglu_registry_url) }
    end

    context 'when snowplow is not enabled' do
      it { is_expected.to allow_value(nil).for(:snowplow_collector_hostname) }
      it { is_expected.to allow_value(nil).for(:snowplow_iglu_registry_url) }
    end

    context "when user accepted let's encrypt terms of service" do
      before do
        setting.update(lets_encrypt_terms_of_service_accepted: true)
      end

      it { is_expected.not_to allow_value(nil).for(:lets_encrypt_notification_email) }
    end

    describe 'EKS integration' do
      before do
        setting.eks_integration_enabled = eks_enabled
      end

      context 'integration is disabled' do
        let(:eks_enabled) { false }

        it { is_expected.to allow_value(nil).for(:eks_account_id) }
        it { is_expected.to allow_value(nil).for(:eks_access_key_id) }
        it { is_expected.to allow_value(nil).for(:eks_secret_access_key) }
      end

      context 'integration is enabled' do
        let(:eks_enabled) { true }

        it { is_expected.to allow_value('123456789012').for(:eks_account_id) }
        it { is_expected.not_to allow_value(nil).for(:eks_account_id) }
        it { is_expected.not_to allow_value('123').for(:eks_account_id) }
        it { is_expected.not_to allow_value('12345678901a').for(:eks_account_id) }

        it { is_expected.to allow_value('access-key-id-12').for(:eks_access_key_id) }
        it { is_expected.not_to allow_value('a' * 129).for(:eks_access_key_id) }
        it { is_expected.not_to allow_value('short-key').for(:eks_access_key_id) }
        it { is_expected.not_to allow_value(nil).for(:eks_access_key_id) }

        it { is_expected.to allow_value('secret-access-key').for(:eks_secret_access_key) }
        it { is_expected.not_to allow_value(nil).for(:eks_secret_access_key) }
      end
    end

    describe 'default_artifacts_expire_in' do
      it 'sets an error if it cannot parse' do
        setting.update(default_artifacts_expire_in: 'a')

        expect_invalid
      end

      it 'sets an error if it is blank' do
        setting.update(default_artifacts_expire_in: ' ')

        expect_invalid
      end

      it 'sets the value if it is valid' do
        setting.update(default_artifacts_expire_in: '30 days')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('30 days')
      end

      it 'sets the value if it is 0' do
        setting.update(default_artifacts_expire_in: '0')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('0')
      end

      def expect_invalid
        expect(setting).to be_invalid
        expect(setting.errors.messages)
          .to have_key(:default_artifacts_expire_in)
      end
    end

    it { is_expected.to validate_presence_of(:max_attachment_size) }

    it do
      is_expected.to validate_numericality_of(:max_attachment_size)
        .only_integer
        .is_greater_than(0)
    end

    it do
      is_expected.to validate_numericality_of(:local_markdown_version)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than(65536)
    end

    context 'key restrictions' do
      it 'supports all key types' do
        expect(described_class::SUPPORTED_KEY_TYPES).to contain_exactly(:rsa, :dsa, :ecdsa, :ed25519)
      end

      it 'does not allow all key types to be disabled' do
        described_class::SUPPORTED_KEY_TYPES.each do |type|
          setting["#{type}_key_restriction"] = described_class::FORBIDDEN_KEY_VALUE
        end

        expect(setting).not_to be_valid
        expect(setting.errors.messages).to have_key(:allowed_key_types)
      end

      where(:type) do
        described_class::SUPPORTED_KEY_TYPES
      end

      with_them do
        let(:field) { :"#{type}_key_restriction" }

        it { is_expected.to validate_presence_of(field) }
        it { is_expected.to allow_value(*KeyRestrictionValidator.supported_key_restrictions(type)).for(field) }
        it { is_expected.not_to allow_value(128).for(field) }
      end
    end

    it_behaves_like 'an object with email-formated attributes', :admin_notification_email do
      subject { setting }
    end

    # Upgraded databases will have this sort of content
    context 'repository_storages is a String, not an Array' do
      before do
        described_class.where(id: setting.id).update_all(repository_storages: 'default')
      end

      it { expect(setting.repository_storages).to eq(['default']) }
    end

    context 'auto_devops_domain setting' do
      context 'when auto_devops_enabled? is true' do
        before do
          setting.update(auto_devops_enabled: true)
        end

        it 'can be blank' do
          setting.update(auto_devops_domain: '')

          expect(setting).to be_valid
        end

        context 'with a valid value' do
          before do
            setting.update(auto_devops_domain: 'domain.com')
          end

          it 'is valid' do
            expect(setting).to be_valid
          end
        end

        context 'with an invalid value' do
          before do
            setting.update(auto_devops_domain: 'definitelynotahostname')
          end

          it 'is invalid' do
            expect(setting).to be_invalid
          end
        end
      end
    end

    context 'repository storages' do
      before do
        storages = {
          'custom1' => 'tmp/tests/custom_repositories_1',
          'custom2' => 'tmp/tests/custom_repositories_2',
          'custom3' => 'tmp/tests/custom_repositories_3'

        }
        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
      end

      describe 'inclusion' do
        it { is_expected.to allow_value('custom1').for(:repository_storages) }
        it { is_expected.to allow_value(%w(custom2 custom3)).for(:repository_storages) }
        it { is_expected.not_to allow_value('alternative').for(:repository_storages) }
        it { is_expected.not_to allow_value(%w(alternative custom1)).for(:repository_storages) }
      end

      describe 'presence' do
        it { is_expected.not_to allow_value([]).for(:repository_storages) }
        it { is_expected.not_to allow_value("").for(:repository_storages) }
        it { is_expected.not_to allow_value(nil).for(:repository_storages) }
      end
    end

    context 'housekeeping settings' do
      it { is_expected.not_to allow_value(0).for(:housekeeping_incremental_repack_period) }

      it 'wants the full repack period to be at least the incremental repack period' do
        subject.housekeeping_incremental_repack_period = 2
        subject.housekeeping_full_repack_period = 1

        expect(subject).not_to be_valid
      end

      it 'wants the gc period to be at least the full repack period' do
        subject.housekeeping_full_repack_period = 100
        subject.housekeeping_gc_period = 90

        expect(subject).not_to be_valid
      end

      it 'allows the same period for incremental repack and full repack, effectively skipping incremental repack' do
        subject.housekeeping_incremental_repack_period = 2
        subject.housekeeping_full_repack_period = 2

        expect(subject).to be_valid
      end

      it 'allows the same period for full repack and gc, effectively skipping full repack' do
        subject.housekeeping_full_repack_period = 100
        subject.housekeeping_gc_period = 100

        expect(subject).to be_valid
      end
    end

    context 'gitaly timeouts' do
      [:gitaly_timeout_default, :gitaly_timeout_medium, :gitaly_timeout_fast].each do |timeout_name|
        it do
          is_expected.to validate_presence_of(timeout_name)
          is_expected.to validate_numericality_of(timeout_name).only_integer
            .is_greater_than_or_equal_to(0)
        end
      end

      [:gitaly_timeout_medium, :gitaly_timeout_fast].each do |timeout_name|
        it "validates that #{timeout_name} is lower than timeout_default" do
          subject[:gitaly_timeout_default] = 50
          subject[timeout_name] = 100

          expect(subject).to be_invalid
        end
      end

      it 'accepts all timeouts equal' do
        subject.gitaly_timeout_default = 0
        subject.gitaly_timeout_medium = 0
        subject.gitaly_timeout_fast = 0

        expect(subject).to be_valid
      end

      it 'accepts timeouts in descending order' do
        subject.gitaly_timeout_default = 50
        subject.gitaly_timeout_medium = 30
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_valid
      end

      it 'rejects timeouts in ascending order' do
        subject.gitaly_timeout_default = 20
        subject.gitaly_timeout_medium = 30
        subject.gitaly_timeout_fast = 50

        expect(subject).to be_invalid
      end

      it 'rejects medium timeout larger than default' do
        subject.gitaly_timeout_default = 30
        subject.gitaly_timeout_medium = 50
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_invalid
      end

      it 'rejects medium timeout smaller than fast' do
        subject.gitaly_timeout_default = 30
        subject.gitaly_timeout_medium = 15
        subject.gitaly_timeout_fast = 20

        expect(subject).to be_invalid
      end
    end

    describe 'enforcing terms' do
      it 'requires the terms to present when enforcing users to accept' do
        subject.enforce_terms = true

        expect(subject).to be_invalid
      end

      it 'is valid when terms are created' do
        create(:term)
        subject.enforce_terms = true

        expect(subject).to be_valid
      end
    end

    describe 'when external authorization service is enabled' do
      before do
        setting.external_authorization_service_enabled = true
      end

      it { is_expected.not_to allow_value('not a URL').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('https://example.com').for(:external_authorization_service_url) }
      it { is_expected.to allow_value('').for(:external_authorization_service_url) }
      it { is_expected.not_to allow_value(nil).for(:external_authorization_service_default_label) }
      it { is_expected.not_to allow_value(11).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value(0).for(:external_authorization_service_timeout) }
      it { is_expected.not_to allow_value('not a certificate').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_cert) }
      it { is_expected.to allow_value('').for(:external_auth_client_key) }

      context 'when setting a valid client certificate for external authorization' do
        let(:certificate_data) { File.read('spec/fixtures/passphrase_x509_certificate.crt') }

        before do
          setting.external_auth_client_cert = certificate_data
        end

        it 'requires a valid client key when a certificate is set' do
          expect(setting).not_to allow_value('fefefe').for(:external_auth_client_key)
        end

        it 'requires a matching certificate' do
          other_private_key = File.read('spec/fixtures/x509_certificate_pk.key')

          expect(setting).not_to allow_value(other_private_key).for(:external_auth_client_key)
        end

        it 'the credentials are valid when the private key can be read and matches the certificate' do
          tls_attributes = [:external_auth_client_key_pass,
                            :external_auth_client_key,
                            :external_auth_client_cert]
          setting.external_auth_client_key = File.read('spec/fixtures/passphrase_x509_certificate_pk.key')
          setting.external_auth_client_key_pass = '5iveL!fe'

          setting.validate

          expect(setting.errors).not_to include(*tls_attributes)
        end
      end
    end

    context 'asset proxy settings' do
      before do
        subject.asset_proxy_enabled = true
      end

      describe '#asset_proxy_url' do
        it { is_expected.not_to allow_value('').for(:asset_proxy_url) }
        it { is_expected.to allow_value(http).for(:asset_proxy_url) }
        it { is_expected.to allow_value(https).for(:asset_proxy_url) }
        it { is_expected.not_to allow_value(ftp).for(:asset_proxy_url) }

        it 'is not required when asset proxy is disabled' do
          subject.asset_proxy_enabled = false
          subject.asset_proxy_url = ''

          expect(subject).to be_valid
        end
      end

      describe '#asset_proxy_secret_key' do
        it { is_expected.not_to allow_value('').for(:asset_proxy_secret_key) }
        it { is_expected.to allow_value('anything').for(:asset_proxy_secret_key) }

        it 'is not required when asset proxy is disabled' do
          subject.asset_proxy_enabled = false
          subject.asset_proxy_secret_key = ''

          expect(subject).to be_valid
        end

        it 'is encrypted' do
          subject.asset_proxy_secret_key = 'shared secret'

          expect(subject.encrypted_asset_proxy_secret_key).to be_present
          expect(subject.encrypted_asset_proxy_secret_key).not_to eq(subject.asset_proxy_secret_key)
        end
      end

      describe '#asset_proxy_whitelist' do
        context 'when given an Array' do
          it 'sets the domains and adds current running host' do
            setting.asset_proxy_whitelist = ['example.com', 'assets.example.com']
            expect(setting.asset_proxy_whitelist).to eq(['example.com', 'assets.example.com', 'localhost'])
          end
        end

        context 'when given a String' do
          it 'sets multiple domains with spaces' do
            setting.asset_proxy_whitelist = 'example.com *.example.com'
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with newlines and a space' do
            setting.asset_proxy_whitelist = "example.com\n *.example.com"
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with commas' do
            setting.asset_proxy_whitelist = "example.com, *.example.com"
            expect(setting.asset_proxy_whitelist).to eq(['example.com', '*.example.com', 'localhost'])
          end
        end
      end
    end

    context 'static objects external storage' do
      context 'when URL is set' do
        before do
          subject.static_objects_external_storage_url = http
        end

        it { is_expected.not_to allow_value(nil).for(:static_objects_external_storage_auth_token) }
      end
    end

    context 'sourcegraph settings' do
      it 'is invalid if sourcegraph is enabled and no url is provided' do
        allow(subject).to receive(:sourcegraph_enabled).and_return(true)

        expect(subject.sourcegraph_url).to be_nil
        is_expected.to be_invalid
      end
    end
  end

  context 'restrict creating duplicates' do
    let!(:current_settings) { described_class.create_from_defaults }

    it 'returns the current settings' do
      expect(described_class.create_from_defaults).to eq(current_settings)
    end
  end

  describe '#disabled_oauth_sign_in_sources=' do
    before do
      allow(Devise).to receive(:omniauth_providers).and_return([:github])
    end

    it 'removes unknown sources (as strings) from the array' do
      subject.disabled_oauth_sign_in_sources = %w[github test]

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to eq ['github']
    end

    it 'removes unknown sources (as symbols) from the array' do
      subject.disabled_oauth_sign_in_sources = %i[github test]

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to eq ['github']
    end

    it 'ignores nil' do
      subject.disabled_oauth_sign_in_sources = nil

      expect(subject).to be_valid
      expect(subject.disabled_oauth_sign_in_sources).to be_empty
    end
  end

  describe 'performance bar settings' do
    describe 'performance_bar_allowed_group' do
      context 'with no performance_bar_allowed_group_id saved' do
        it 'returns nil' do
          expect(setting.performance_bar_allowed_group).to be_nil
        end
      end

      context 'with a performance_bar_allowed_group_id saved' do
        let(:group) { create(:group) }

        before do
          setting.update!(performance_bar_allowed_group_id: group.id)
        end

        it 'returns the group' do
          expect(setting.reload.performance_bar_allowed_group).to eq(group)
        end
      end
    end

    describe 'performance_bar_enabled' do
      context 'with the Performance Bar is enabled' do
        let(:group) { create(:group) }

        before do
          setting.update!(performance_bar_allowed_group_id: group.id)
        end

        it 'returns true' do
          expect(setting.reload.performance_bar_enabled).to be_truthy
        end
      end
    end
  end

  context 'diff limit settings' do
    describe '#diff_max_patch_bytes' do
      context 'validations' do
        it { is_expected.to validate_presence_of(:diff_max_patch_bytes) }

        it do
          is_expected.to validate_numericality_of(:diff_max_patch_bytes)
          .only_integer
          .is_greater_than_or_equal_to(Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES)
          .is_less_than_or_equal_to(Gitlab::Git::Diff::MAX_PATCH_BYTES_UPPER_BOUND)
        end
      end
    end
  end

  describe '#sourcegraph_url_is_com?' do
    where(:url, :is_com) do
      'https://sourcegraph.com' | true
      'https://sourcegraph.com/' | true
      'https://www.sourcegraph.com' | true
      'shttps://www.sourcegraph.com' | false
      'https://sourcegraph.example.com/' | false
      'https://sourcegraph.org/' | false
    end

    with_them do
      it 'matches the url with sourcegraph.com' do
        setting.sourcegraph_url = url

        expect(setting.sourcegraph_url_is_com?).to eq(is_com)
      end
    end
  end

  it_behaves_like 'application settings examples'
end
