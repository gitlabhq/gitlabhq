# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::InsecureKeyFingerprint do
  let(:key) do
    'ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn' \
    '1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qk' \
    'r8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMg' \
    'Jw0='
  end

  let(:fingerprint) { "3f:a2:ee:de:b5:de:53:c3:aa:2f:9c:45:24:4c:47:7b" }
  let(:fingerprint_sha256) { "MQHWhS9nhzUezUdD42ytxubZoBKrZLbyBZzxCkmnxXc" }

  describe "#fingerprint" do
    it "generates the key's fingerprint" do
      expect(described_class.new(key.split[1]).fingerprint_md5).to eq(fingerprint)
    end
  end

  describe "#fingerprint" do
    it "generates the key's fingerprint" do
      expect(described_class.new(key.split[1]).fingerprint_sha256).to eq(fingerprint_sha256)
    end
  end
end
