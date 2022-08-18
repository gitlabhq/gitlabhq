# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::InsecureKeyFingerprint do
  let(:key) do
    'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn' \
    '1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qk' \
    'r8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMg' \
    'Jw0='
  end

  let(:fingerprint_sha256) { "MQHWhS9nhzUezUdD42ytxubZoBKrZLbyBZzxCkmnxXc" }

  describe '#fingerprint_sha256' do
    it "generates the key's fingerprint" do
      expect(described_class.new(key.split[1]).fingerprint_sha256).to eq(fingerprint_sha256)
    end
  end
end
