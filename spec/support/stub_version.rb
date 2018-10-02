# frozen_string_literal: true

module StubVersion
  def stub_version(version, revision)
    stub_const('Gitlab::VERSION', version)
    allow(Gitlab).to receive(:revision).and_return(revision)
  end
end
