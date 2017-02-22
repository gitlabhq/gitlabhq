module StubConfiguration
  def stub_application_setting(messages)
    add_predicates(messages)

    # Stubbing both of these because we're not yet consistent with how we access
    # current application settings
    allow_any_instance_of(ApplicationSetting).to receive_messages(messages)
    allow(Gitlab::CurrentSettings.current_application_settings).
      to receive_messages(messages)
  end

  def stub_config_setting(messages)
    allow(Gitlab.config.gitlab).to receive_messages(messages)
  end

  def stub_gravatar_setting(messages)
    allow(Gitlab.config.gravatar).to receive_messages(messages)
  end

  def stub_incoming_email_setting(messages)
    allow(Gitlab.config.incoming_email).to receive_messages(messages)
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
end
