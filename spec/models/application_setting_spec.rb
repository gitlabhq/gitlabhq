# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSetting do
  using RSpec::Parameterized::TableSyntax

  subject(:setting) { described_class.create_from_defaults }

  it { include(CacheableAttributes) }
  it { include(ApplicationSettingImplementation) }
  it { expect(described_class.current_without_cache).to eq(described_class.last) }

  it { expect(setting).to be_valid }
  it { expect(setting.uuid).to be_present }
  it { expect(setting).to have_db_column(:auto_devops_enabled) }

  describe 'validations' do
    let(:http)  { 'http://example.com' }
    let(:https) { 'https://example.com' }
    let(:ftp)   { 'ftp://example.com' }
    let(:javascript) { 'javascript:alert(window.opener.document.location)' }

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

    it { is_expected.to allow_value(true).for(:container_expiration_policies_enable_historic_entries) }
    it { is_expected.to allow_value(false).for(:container_expiration_policies_enable_historic_entries) }
    it { is_expected.not_to allow_value(nil).for(:container_expiration_policies_enable_historic_entries) }

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

    it { is_expected.to validate_numericality_of(:container_registry_delete_tags_service_timeout).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:container_registry_cleanup_tags_service_max_list_size).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:container_registry_expiration_policies_worker_capacity).only_integer.is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_numericality_of(:snippet_size_limit).only_integer.is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:wiki_page_max_content_bytes).only_integer.is_greater_than_or_equal_to(1024) }
    it { is_expected.to validate_presence_of(:max_artifacts_size) }
    it { is_expected.to validate_numericality_of(:max_artifacts_size).only_integer.is_greater_than(0) }
    it { is_expected.to validate_presence_of(:max_pages_size) }
    it 'ensures max_pages_size is an integer greater than 0 (or equal to 0 to indicate unlimited/maximum)' do
      is_expected.to validate_numericality_of(:max_pages_size).only_integer.is_greater_than_or_equal_to(0)
                       .is_less_than(::Gitlab::Pages::MAX_SIZE / 1.megabyte)
    end

    it { is_expected.not_to allow_value(7).for(:minimum_password_length) }
    it { is_expected.not_to allow_value(129).for(:minimum_password_length) }
    it { is_expected.not_to allow_value(nil).for(:minimum_password_length) }
    it { is_expected.not_to allow_value('abc').for(:minimum_password_length) }
    it { is_expected.to allow_value(10).for(:minimum_password_length) }

    it { is_expected.to allow_value(300).for(:issues_create_limit) }
    it { is_expected.not_to allow_value('three').for(:issues_create_limit) }
    it { is_expected.not_to allow_value(nil).for(:issues_create_limit) }
    it { is_expected.not_to allow_value(10.5).for(:issues_create_limit) }
    it { is_expected.not_to allow_value(-1).for(:issues_create_limit) }

    it { is_expected.to allow_value(0).for(:raw_blob_request_limit) }
    it { is_expected.not_to allow_value('abc').for(:raw_blob_request_limit) }
    it { is_expected.not_to allow_value(nil).for(:raw_blob_request_limit) }
    it { is_expected.not_to allow_value(10.5).for(:raw_blob_request_limit) }
    it { is_expected.not_to allow_value(-1).for(:raw_blob_request_limit) }

    it { is_expected.not_to allow_value(false).for(:hashed_storage_enabled) }

    it { is_expected.to allow_value('default' => 0).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => 50).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => 100).for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => '90').for(:repository_storages_weighted) }
    it { is_expected.to allow_value('default' => nil).for(:repository_storages_weighted) }
    it { is_expected.not_to allow_value('default' => -1).for(:repository_storages_weighted).with_message("value for 'default' must be between 0 and 100") }
    it { is_expected.not_to allow_value('default' => 101).for(:repository_storages_weighted).with_message("value for 'default' must be between 0 and 100") }
    it { is_expected.not_to allow_value('default' => 100, shouldntexist: 50).for(:repository_storages_weighted).with_message("can't include: shouldntexist") }

    it { is_expected.to allow_value(400).for(:notes_create_limit) }
    it { is_expected.not_to allow_value('two').for(:notes_create_limit) }
    it { is_expected.not_to allow_value(nil).for(:notes_create_limit) }
    it { is_expected.not_to allow_value(5.5).for(:notes_create_limit) }
    it { is_expected.not_to allow_value(-2).for(:notes_create_limit) }

    def many_usernames(num = 100)
      Array.new(num) { |i| "username#{i}" }
    end

    it { is_expected.to allow_value(many_usernames(100)).for(:notes_create_limit_allowlist) }
    it { is_expected.not_to allow_value(many_usernames(101)).for(:notes_create_limit_allowlist) }
    it { is_expected.not_to allow_value(nil).for(:notes_create_limit_allowlist) }
    it { is_expected.to allow_value([]).for(:notes_create_limit_allowlist) }

    it { is_expected.to allow_value('all_tiers').for(:whats_new_variant) }
    it { is_expected.to allow_value('current_tier').for(:whats_new_variant) }
    it { is_expected.to allow_value('disabled').for(:whats_new_variant) }
    it { is_expected.not_to allow_value(nil).for(:whats_new_variant) }

    it { is_expected.not_to allow_value(['']).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(['OBVIOUSLY_WRONG']).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(%w(project project)).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value([nil]).for(:valid_runner_registrars) }
    it { is_expected.not_to allow_value(nil).for(:valid_runner_registrars) }
    it { is_expected.to allow_value([]).for(:valid_runner_registrars) }
    it { is_expected.to allow_value(%w(project group)).for(:valid_runner_registrars) }

    context 'help_page_documentation_base_url validations' do
      it { is_expected.to allow_value(nil).for(:help_page_documentation_base_url) }
      it { is_expected.to allow_value('https://docs.gitlab.com').for(:help_page_documentation_base_url) }
      it { is_expected.to allow_value('http://127.0.0.1').for(:help_page_documentation_base_url) }
      it { is_expected.not_to allow_value('docs.gitlab.com').for(:help_page_documentation_base_url) }

      context 'when url length validation' do
        let(:value) { 'http://'.ljust(length, 'A') }

        context 'when value string length is 255 characters' do
          let(:length) { 255 }

          it 'allows the value' do
            is_expected.to allow_value(value).for(:help_page_documentation_base_url)
          end
        end

        context 'when value string length exceeds 255 characters' do
          let(:length) { 256 }

          it 'does not allow the value' do
            is_expected.not_to allow_value(value)
                                 .for(:help_page_documentation_base_url)
                                 .with_message('is too long (maximum is 255 characters)')
          end
        end
      end
    end

    context 'grafana_url validations' do
      before do
        subject.instance_variable_set(:@parsed_grafana_url, nil)
      end

      it { is_expected.to allow_value(http).for(:grafana_url) }
      it { is_expected.to allow_value(https).for(:grafana_url) }
      it { is_expected.not_to allow_value(ftp).for(:grafana_url) }
      it { is_expected.not_to allow_value(javascript).for(:grafana_url) }
      it { is_expected.to allow_value('/-/grafana').for(:grafana_url) }
      it { is_expected.to allow_value('http://localhost:9000').for(:grafana_url) }

      context 'when local URLs are not allowed in system hooks' do
        before do
          stub_application_setting(allow_local_requests_from_system_hooks: false)
        end

        it { is_expected.not_to allow_value('http://localhost:9000').for(:grafana_url) }
      end

      context 'with invalid grafana URL' do
        it 'adds an error' do
          subject.grafana_url = ' ' + http
          expect(subject.save).to be false

          expect(subject.errors[:grafana_url]).to eq([
            'must be a valid relative or absolute URL. ' \
            'Please check your Grafana URL setting in ' \
            'Admin Area > Settings > Metrics and profiling > Metrics - Grafana'
          ])
        end
      end

      context 'with blocked grafana URL' do
        it 'adds an error' do
          subject.grafana_url = javascript
          expect(subject.save).to be false

          expect(subject.errors[:grafana_url]).to eq([
            'is blocked: Only allowed schemes are http, https. Please check your ' \
            'Grafana URL setting in ' \
            'Admin Area > Settings > Metrics and profiling > Metrics - Grafana'
          ])
        end
      end
    end

    describe 'spam_check_endpoint' do
      context 'when spam_check_endpoint is enabled' do
        before do
          setting.spam_check_endpoint_enabled = true
        end

        it { is_expected.to allow_value('grpc://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('https://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('nonsense').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value(nil).for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('').for(:spam_check_endpoint_url) }
      end

      context 'when spam_check_endpoint is NOT enabled' do
        before do
          setting.spam_check_endpoint_enabled = false
        end

        it { is_expected.to allow_value('grpc://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('https://example.org/spam_check').for(:spam_check_endpoint_url) }
        it { is_expected.not_to allow_value('nonsense').for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value(nil).for(:spam_check_endpoint_url) }
        it { is_expected.to allow_value('').for(:spam_check_endpoint_url) }
      end
    end

    context 'when snowplow is enabled' do
      before do
        setting.snowplow_enabled = true
      end

      it { is_expected.not_to allow_value(nil).for(:snowplow_collector_hostname) }
      it { is_expected.to allow_value("snowplow.gitlab.com").for(:snowplow_collector_hostname) }
      it { is_expected.not_to allow_value('/example').for(:snowplow_collector_hostname) }
    end

    context 'when snowplow is not enabled' do
      it { is_expected.to allow_value(nil).for(:snowplow_collector_hostname) }
    end

    context 'when mailgun_events_enabled is enabled' do
      before do
        setting.mailgun_events_enabled = true
      end

      it { is_expected.to validate_presence_of(:mailgun_signing_key) }
      it { is_expected.to validate_length_of(:mailgun_signing_key).is_at_most(255) }
    end

    context 'when mailgun_events_enabled is not enabled' do
      it { is_expected.not_to validate_presence_of(:mailgun_signing_key) }
    end

    context "when user accepted let's encrypt terms of service" do
      before do
        expect do
          setting.update!(lets_encrypt_terms_of_service_accepted: true)
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Lets encrypt notification email can't be blank")
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
        it { is_expected.to allow_value(nil).for(:eks_access_key_id) }

        it { is_expected.to allow_value('secret-access-key').for(:eks_secret_access_key) }
        it { is_expected.to allow_value(nil).for(:eks_secret_access_key) }
      end

      context 'access key is specified' do
        let(:eks_enabled) { true }

        before do
          setting.eks_access_key_id = '123456789012'
        end

        it { is_expected.to allow_value('secret-access-key').for(:eks_secret_access_key) }
        it { is_expected.not_to allow_value(nil).for(:eks_secret_access_key) }
      end
    end

    describe 'default_artifacts_expire_in' do
      it 'sets an error if it cannot parse' do
        expect do
          setting.update!(default_artifacts_expire_in: 'a')
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Default artifacts expire in is not a correct duration")

        expect_invalid
      end

      it 'sets an error if it is blank' do
        expect do
          setting.update!(default_artifacts_expire_in: ' ')
        end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Default artifacts expire in can't be blank")

        expect_invalid
      end

      it 'sets the value if it is valid' do
        setting.update!(default_artifacts_expire_in: '30 days')

        expect(setting).to be_valid
        expect(setting.default_artifacts_expire_in).to eq('30 days')
      end

      it 'sets the value if it is 0' do
        setting.update!(default_artifacts_expire_in: '0')

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

    specify do
      is_expected.to validate_numericality_of(:max_attachment_size)
        .only_integer
        .is_greater_than(0)
    end

    it { is_expected.to validate_presence_of(:max_import_size) }

    specify do
      is_expected.to validate_numericality_of(:max_import_size)
        .only_integer
        .is_greater_than_or_equal_to(0)
    end

    specify do
      is_expected.to validate_numericality_of(:local_markdown_version)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than(65536)
    end

    describe 'usage_ping_enabled setting' do
      shared_examples 'usage ping enabled' do
        it do
          expect(setting.usage_ping_enabled).to eq(true)
          expect(setting.usage_ping_enabled?).to eq(true)
        end
      end

      shared_examples 'usage ping disabled' do
        it do
          expect(setting.usage_ping_enabled).to eq(false)
          expect(setting.usage_ping_enabled?).to eq(false)
        end
      end

      context 'when setting is in database' do
        context 'with usage_ping_enabled disabled' do
          before do
            setting.update!(usage_ping_enabled: false)
          end

          it_behaves_like 'usage ping disabled'
        end

        context 'with usage_ping_enabled enabled' do
          before do
            setting.update!(usage_ping_enabled: true)
          end

          it_behaves_like 'usage ping enabled'
        end
      end

      context 'when setting is in GitLab config' do
        context 'with usage_ping_enabled disabled' do
          before do
            allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
          end

          it_behaves_like 'usage ping disabled'
        end

        context 'with usage_ping_enabled enabled' do
          before do
            allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
          end

          it_behaves_like 'usage ping enabled'
        end
      end

      context 'when setting in database false and setting in GitLab config true' do
        before do
          setting.update!(usage_ping_enabled: false)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
        end

        it_behaves_like 'usage ping disabled'
      end

      context 'when setting database true and setting in GitLab config false' do
        before do
          setting.update!(usage_ping_enabled: true)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(false)
        end

        it_behaves_like 'usage ping disabled'
      end

      context 'when setting database true and setting in GitLab config true' do
        before do
          setting.update!(usage_ping_enabled: true)
          allow(Settings.gitlab).to receive(:usage_ping_enabled).and_return(true)
        end

        it_behaves_like 'usage ping enabled'
      end
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

    it_behaves_like 'an object with email-formatted attributes', :abuse_notification_email do
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
          setting.update!(auto_devops_enabled: true)
        end

        it 'can be blank' do
          setting.update!(auto_devops_domain: '')

          expect(setting).to be_valid
        end

        context 'with a valid value' do
          before do
            setting.update!(auto_devops_domain: 'domain.com')
          end

          it 'is valid' do
            expect(setting).to be_valid
          end
        end

        context 'with an invalid value' do
          before do
            expect do
              setting.update!(auto_devops_domain: 'definitelynotahostname')
            end.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Auto devops domain is not a fully qualified domain name")
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
      it "validates that the default_timeout is lower than the max_request_duration" do
        is_expected.to validate_numericality_of(:gitaly_timeout_default)
          .is_less_than_or_equal_to(Settings.gitlab.max_request_duration_seconds)
      end

      [:gitaly_timeout_default, :gitaly_timeout_medium, :gitaly_timeout_fast].each do |timeout_name|
        specify do
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

      it 'does not prevent from saving when gitaly timeouts were previously invalid' do
        subject.update_column(:gitaly_timeout_default, Settings.gitlab.max_request_duration_seconds + 1)

        expect(subject.reload).to be_valid
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

      describe '#asset_proxy_allowlist' do
        context 'when given an Array' do
          it 'sets the domains and adds current running host' do
            setting.asset_proxy_allowlist = ['example.com', 'assets.example.com']
            expect(setting.asset_proxy_allowlist).to eq(['example.com', 'assets.example.com', 'localhost'])
          end
        end

        context 'when given a String' do
          it 'sets multiple domains with spaces' do
            setting.asset_proxy_allowlist = 'example.com *.example.com'
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with newlines and a space' do
            setting.asset_proxy_allowlist = "example.com\n *.example.com"
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end

          it 'sets multiple domains with commas' do
            setting.asset_proxy_allowlist = "example.com, *.example.com"
            expect(setting.asset_proxy_allowlist).to eq(['example.com', '*.example.com', 'localhost'])
          end
        end
      end

      describe '#ci_jwt_signing_key' do
        it { is_expected.not_to allow_value('').for(:ci_jwt_signing_key) }
        it { is_expected.not_to allow_value('invalid RSA key').for(:ci_jwt_signing_key) }
        it { is_expected.to allow_value(nil).for(:ci_jwt_signing_key) }
        it { is_expected.to allow_value(OpenSSL::PKey::RSA.new(1024).to_pem).for(:ci_jwt_signing_key) }

        it 'is encrypted' do
          subject.ci_jwt_signing_key = OpenSSL::PKey::RSA.new(1024).to_pem

          aggregate_failures do
            expect(subject.encrypted_ci_jwt_signing_key).to be_present
            expect(subject.encrypted_ci_jwt_signing_key_iv).to be_present
            expect(subject.encrypted_ci_jwt_signing_key).not_to eq(subject.ci_jwt_signing_key)
          end
        end
      end

      describe '#cloud_license_auth_token' do
        it { is_expected.to allow_value(nil).for(:cloud_license_auth_token) }

        it 'is encrypted' do
          subject.cloud_license_auth_token = 'token-from-customers-dot'

          aggregate_failures do
            expect(subject.encrypted_cloud_license_auth_token).to be_present
            expect(subject.encrypted_cloud_license_auth_token_iv).to be_present
            expect(subject.encrypted_cloud_license_auth_token).not_to eq(subject.cloud_license_auth_token)
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

    context 'gitpod settings' do
      it 'is invalid if gitpod is enabled and no url is provided' do
        allow(subject).to receive(:gitpod_enabled).and_return(true)
        allow(subject).to receive(:gitpod_url).and_return(nil)

        is_expected.to be_invalid
      end

      it 'is invalid if gitpod is enabled and an empty url is provided' do
        allow(subject).to receive(:gitpod_enabled).and_return(true)
        allow(subject).to receive(:gitpod_url).and_return('')

        is_expected.to be_invalid
      end

      it 'is invalid if gitpod is enabled and an invalid url is provided' do
        allow(subject).to receive(:gitpod_enabled).and_return(true)
        allow(subject).to receive(:gitpod_url).and_return('javascript:alert("test")//')

        is_expected.to be_invalid
      end
    end

    context 'throttle_* settings' do
      where(:throttle_setting) do
        %i[
          throttle_unauthenticated_requests_per_period
          throttle_unauthenticated_period_in_seconds
          throttle_authenticated_api_requests_per_period
          throttle_authenticated_api_period_in_seconds
          throttle_authenticated_web_requests_per_period
          throttle_authenticated_web_period_in_seconds
          throttle_unauthenticated_packages_api_requests_per_period
          throttle_unauthenticated_packages_api_period_in_seconds
          throttle_authenticated_packages_api_requests_per_period
          throttle_authenticated_packages_api_period_in_seconds
        ]
      end

      with_them do
        it { is_expected.to allow_value(3).for(throttle_setting) }
        it { is_expected.not_to allow_value(-3).for(throttle_setting) }
        it { is_expected.not_to allow_value(0).for(throttle_setting) }
        it { is_expected.not_to allow_value('three').for(throttle_setting) }
        it { is_expected.not_to allow_value(nil).for(throttle_setting) }
      end
    end
  end

  context 'restrict creating duplicates' do
    let!(:current_settings) { described_class.create_from_defaults }

    it 'returns the current settings' do
      expect(described_class.create_from_defaults).to eq(current_settings)
    end
  end

  context 'when ApplicationSettings does not have a primary key' do
    before do
      allow(ActiveRecord::Base.connection).to receive(:primary_key).with(described_class.table_name).and_return(nil)
    end

    it 'raises an exception' do
      expect { described_class.create_from_defaults }.to raise_error(/table is missing a primary key constraint/)
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

        specify do
          is_expected.to validate_numericality_of(:diff_max_patch_bytes)
          .only_integer
          .is_greater_than_or_equal_to(Gitlab::Git::Diff::DEFAULT_MAX_PATCH_BYTES)
          .is_less_than_or_equal_to(Gitlab::Git::Diff::MAX_PATCH_BYTES_UPPER_BOUND)
        end
      end
    end

    describe '#diff_max_files' do
      context 'validations' do
        it { is_expected.to validate_presence_of(:diff_max_files) }

        specify do
          is_expected
            .to validate_numericality_of(:diff_max_files)
            .only_integer
            .is_greater_than_or_equal_to(Commit::DEFAULT_MAX_DIFF_FILES_SETTING)
            .is_less_than_or_equal_to(Commit::MAX_DIFF_FILES_SETTING_UPPER_BOUND)
        end
      end
    end

    describe '#diff_max_lines' do
      context 'validations' do
        it { is_expected.to validate_presence_of(:diff_max_lines) }

        specify do
          is_expected
            .to validate_numericality_of(:diff_max_lines)
            .only_integer
            .is_greater_than_or_equal_to(Commit::DEFAULT_MAX_DIFF_LINES_SETTING)
            .is_less_than_or_equal_to(Commit::MAX_DIFF_LINES_SETTING_UPPER_BOUND)
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

  describe '#instance_review_permitted?', :request_store, :use_clean_rails_memory_store_caching do
    subject { setting.instance_review_permitted? }

    before do
      allow(License).to receive(:current).and_return(nil) if Gitlab.ee?
      allow(Rails.cache).to receive(:fetch).and_call_original
      expect(Rails.cache).to receive(:fetch).with('limited_users_count', anything).and_return(
        ::ApplicationSetting::INSTANCE_REVIEW_MIN_USERS + users_over_minimum
      )
    end

    where(users_over_minimum: [-1, 0, 1])

    with_them do
      it { is_expected.to be(users_over_minimum >= 0) }
    end
  end

  describe 'email_restrictions' do
    context 'when email restrictions are enabled' do
      before do
        subject.email_restrictions_enabled = true
      end

      it 'allows empty email restrictions' do
        subject.email_restrictions = ''

        expect(subject).to be_valid
      end

      it 'accepts valid email restrictions regex' do
        subject.email_restrictions = '\+'

        expect(subject).to be_valid
      end

      it 'does not accept invalid email restrictions regex' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
      end

      it 'sets an error when regex is not valid' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
        expect(subject.errors.messages[:email_restrictions].first).to eq(_('not valid RE2 syntax: no argument for repetition operator: +'))
      end
    end

    context 'when email restrictions are disabled' do
      before do
        subject.email_restrictions_enabled = false
      end

      it 'allows empty email restrictions' do
        subject.email_restrictions = ''

        expect(subject).to be_valid
      end

      it 'invalid regex is not valid' do
        subject.email_restrictions = '+'

        expect(subject).not_to be_valid
      end
    end
  end

  it_behaves_like 'application settings examples'

  describe 'kroki_format_supported?' do
    it 'returns true when Excalidraw is enabled' do
      subject.kroki_formats_excalidraw = true
      expect(subject.kroki_format_supported?('excalidraw')).to eq(true)
    end

    it 'returns true when BlockDiag is enabled' do
      subject.kroki_formats_blockdiag = true
      # format "blockdiag" aggregates multiple diagram types: actdiag, blockdiag, nwdiag...
      expect(subject.kroki_format_supported?('actdiag')).to eq(true)
      expect(subject.kroki_format_supported?('blockdiag')).to eq(true)
    end

    it 'returns false when BlockDiag is disabled' do
      subject.kroki_formats_blockdiag = false
      # format "blockdiag" aggregates multiple diagram types: actdiag, blockdiag, nwdiag...
      expect(subject.kroki_format_supported?('actdiag')).to eq(false)
      expect(subject.kroki_format_supported?('blockdiag')).to eq(false)
    end

    it 'returns false when the diagram type is optional and not enabled' do
      expect(subject.kroki_format_supported?('bpmn')).to eq(false)
    end

    it 'returns true when the diagram type is enabled by default' do
      expect(subject.kroki_format_supported?('vegalite')).to eq(true)
      expect(subject.kroki_format_supported?('nomnoml')).to eq(true)
      expect(subject.kroki_format_supported?('unknown-diagram-type')).to eq(false)
    end

    it 'returns false when the diagram type is unknown' do
      expect(subject.kroki_format_supported?('unknown-diagram-type')).to eq(false)
    end
  end

  describe 'kroki_formats' do
    it 'returns the value for kroki_formats' do
      subject.kroki_formats = { blockdiag: true, bpmn: false, excalidraw: true }
      expect(subject.kroki_formats_blockdiag).to eq(true)
      expect(subject.kroki_formats_bpmn).to eq(false)
      expect(subject.kroki_formats_excalidraw).to eq(true)
    end
  end
end
