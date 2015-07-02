module StubConfiguration
  def stub_application_setting(messages)
    allow(Gitlab::CurrentSettings.current_application_settings).
      to receive_messages(messages)
  end

  def stub_config_setting(messages)
    allow(Gitlab.config.gitlab).to receive_messages(messages)
  end

  def stub_gravatar_setting(messages)
    allow(Gitlab.config.gravatar).to receive_messages(messages)
  end
end
