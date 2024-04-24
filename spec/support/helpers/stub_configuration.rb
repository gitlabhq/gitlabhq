# frozen_string_literal: true

require 'gitlab_edition'
require 'active_support/hash_with_indifferent_access'
require 'active_support/dependencies'

# check gets rid of already initialized constant warnings when using spring
require_dependency 'gitlab' unless defined?(Gitlab)

module StubConfiguration
  def stub_application_setting(messages)
    add_predicates(messages)

    # Stubbing both of these because we're not yet consistent with how we access
    # current application settings
    allow_any_instance_of(ApplicationSetting).to receive_messages(to_settings(messages))
    allow(Gitlab::CurrentSettings.current_application_settings)
      .to receive_messages(to_settings(messages))

    # Ensure that we don't use the Markdown cache when stubbing these values
    allow_any_instance_of(ApplicationSetting).to receive(:cached_html_up_to_date?).and_return(false)
  end

  # For enums with `_prefix: true`, this allows us to stub the application setting properly
  def stub_application_setting_enum(setting, value)
    stub_application_setting(setting.to_sym => value)

    ApplicationSetting.send(setting.pluralize.to_sym).each_key do |key|
      stub_application_setting("#{setting}_#{key}".to_sym => key == value)
    end

    Gitlab::CurrentSettings.send(setting)
  end

  def stub_not_protect_default_branch
    stub_application_setting(
      default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    stub_application_setting(default_branch_protection_defaults: Gitlab::Access::BranchProtection.protection_none)
  end

  def stub_config_setting(messages)
    allow(Gitlab.config.gitlab).to receive_messages(to_settings(messages))
  end

  def stub_config(messages)
    allow(Gitlab.config).to receive_messages(to_settings(messages))
  end

  def stub_default_url_options(host: "localhost", protocol: "http", script_name: nil)
    url_options = { host: host, protocol: protocol, script_name: script_name }
    allow(Rails.application.routes).to receive(:default_url_options).and_return(url_options)
  end

  def stub_dependency_proxy_setting(messages)
    allow(Gitlab.config.dependency_proxy).to receive_messages(to_settings(messages))
  end

  def stub_gravatar_setting(messages)
    allow(Gitlab.config.gravatar).to receive_messages(to_settings(messages))
  end

  def stub_incoming_email_setting(messages)
    allow(Gitlab.config.incoming_email).to receive_messages(to_settings(messages))
  end

  def stub_mattermost_setting(messages)
    allow(Gitlab.config.mattermost).to receive_messages(to_settings(messages))
  end

  def stub_omniauth_setting(messages)
    allow(Gitlab.config.omniauth).to receive_messages(to_settings(messages))
  end

  def stub_backup_setting(messages)
    allow(Gitlab.config.backup).to receive_messages(to_settings(messages))
  end

  def stub_lfs_setting(messages)
    allow(Gitlab.config.lfs).to receive_messages(to_settings(messages))
  end

  def stub_external_diffs_setting(messages)
    allow(Gitlab.config.external_diffs).to receive_messages(to_settings(messages))
  end

  def stub_artifacts_setting(messages)
    allow(Gitlab.config.artifacts).to receive_messages(to_settings(messages))
  end

  def stub_pages_setting(messages)
    allow(Gitlab.config.pages).to receive_messages(to_settings(messages))
  end

  def stub_storage_settings(messages)
    messages.deep_stringify_keys!

    # Default storage is always required
    messages['default'] ||= Gitlab.config.repositories.storages[GitalySetup::REPOS_STORAGE]
    messages.each do |storage_name, storage_hash|
      # Default additional storages to connect to the default storage
      unless storage_hash.key?('gitaly_address')
        storage_hash['gitaly_address'] = Gitlab.config.repositories.storages[GitalySetup::REPOS_STORAGE].gitaly_address
      end

      messages[storage_name] = Gitlab::GitalyClient::StorageSettings.new(storage_hash.to_h)
    end

    allow(Gitlab.config.repositories).to receive(:storages).and_return(::GitlabSettings::Options.build(messages))
  end

  def stub_sentry_settings(enabled: true)
    allow(Gitlab::CurrentSettings).to receive(:sentry_enabled?) { enabled }

    dsn = 'dummy://b44a0828b72421a6d8e99efd68d44fa8@example.com/42'
    allow(Gitlab::CurrentSettings).to receive(:sentry_dsn) { dsn }

    clientside_dsn = 'dummy://b44a0828b72421a6d8e99efd68d44fa8@example.com/43'
    allow(Gitlab::CurrentSettings)
      .to receive(:sentry_clientside_dsn) { clientside_dsn }
  end

  def clear_sentry_settings
    Sentry.get_current_scope.clear
  end

  def stub_microsoft_graph_mailer_setting(messages)
    allow(Gitlab.config.microsoft_graph_mailer).to receive_messages(to_settings(messages))
  end

  def stub_kerberos_setting(messages)
    allow(Gitlab.config.kerberos).to receive_messages(to_settings(messages))
  end

  def stub_gitlab_shell_setting(messages)
    allow(Gitlab.config.gitlab_shell).to receive_messages(to_settings(messages))
  end

  def stub_asset_proxy_setting(messages)
    allow(Gitlab.config.asset_proxy).to receive_messages(to_settings(messages))
  end

  def stub_rack_attack_setting(messages)
    allow(Gitlab.config.rack_attack).to receive(:git_basic_auth).and_return(messages)
    allow(Gitlab.config.rack_attack.git_basic_auth).to receive_messages(to_settings(messages))
  end

  def stub_service_desk_email_setting(messages)
    allow(::Gitlab.config.service_desk_email).to receive_messages(to_settings(messages))
  end

  def stub_packages_setting(messages)
    allow(::Gitlab.config.packages).to receive_messages(to_settings(messages))
  end

  def stub_maintenance_mode_setting(value)
    allow(Gitlab::CurrentSettings).to receive(:current_application_settings?).and_return(true)

    stub_application_setting(maintenance_mode: value)
  end

  def stub_usage_ping_features(value)
    stub_application_setting(usage_ping_enabled: value)
    stub_application_setting(usage_ping_features_enabled: value)
  end

  private

  # Modifies stubbed messages to also stub possible predicate versions
  #
  # Examples:
  #
  #   add_predicates(foo: true)
  #   # => {foo: true, foo?: true}
  #
  #   add_predicates(signup_enabled?: false)
  #   # => {signup_enabled? false}
  def add_predicates(messages)
    # Only modify keys that aren't already predicates
    keys = messages.keys.map(&:to_s).reject { |k| k.end_with?('?') }

    keys.each do |key|
      predicate = key + '?'
      messages[predicate.to_sym] = messages[key.to_sym]
    end
  end

  # Support nested hashes by converting all values into GitlabSettings::Objects objects
  def to_settings(hash)
    hash.transform_values do |value|
      if value.is_a? Hash
        ::GitlabSettings::Options.build(value)
      else
        value
      end
    end
  end
end

require_relative '../../../ee/spec/support/helpers/ee/stub_configuration' if
  GitlabEdition.ee?

StubConfiguration.prepend_mod_with('StubConfiguration')
