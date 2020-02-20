# frozen_string_literal: true

require 'timeout'

RSpec.shared_examples 'malicious regexp' do
  let(:malicious_text) { 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!' }
  let(:malicious_regexp_re2) { '(?i)^(([a-z])+.)+[A-Z]([a-z])+$' }
  let(:malicious_regexp_ruby) { '/^(([a-z])+.)+[A-Z]([a-z])+$/i' }

  it 'takes under a second' do
    expect { Timeout.timeout(1) { subject } }.not_to raise_error
  end
end
