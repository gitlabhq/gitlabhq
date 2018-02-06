# Inspired by https://github.com/ljkbennett/stub_env/blob/master/lib/stub_env/helpers.rb
module StubENV
  def stub_env(key_or_hash, value = nil)
    init_stub unless env_stubbed?

    if key_or_hash.is_a? Hash
      key_or_hash.each { |k, v| add_stubbed_value(k, v) }
    else
      add_stubbed_value key_or_hash, value
    end
  end

  private

  STUBBED_KEY = '__STUBBED__'.freeze

  def add_stubbed_value(key, value)
    allow(ENV).to receive(:[]).with(key).and_return(value)
    allow(ENV).to receive(:key?).with(key).and_return(true)
    allow(ENV).to receive(:fetch).with(key).and_return(value)
    allow(ENV).to receive(:fetch).with(key, anything()) do |_, default_val|
      value || default_val
    end
  end

  def env_stubbed?
    ENV[STUBBED_KEY]
  end

  def init_stub
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:key?).and_call_original
    allow(ENV).to receive(:fetch).and_call_original
    add_stubbed_value(STUBBED_KEY, true)
  end
end
