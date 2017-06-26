module StubENV
  def stub_env(key, value)
    allow(ENV).to receive(:[]).and_call_original unless @env_already_stubbed
    @env_already_stubbed ||= true
    allow(ENV).to receive(:[]).with(key).and_return(value)
  end
end
