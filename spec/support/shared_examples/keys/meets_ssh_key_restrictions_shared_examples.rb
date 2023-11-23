# frozen_string_literal: true

require 'spec_helper'

# Requires a context with:
# - subject
#
RSpec.shared_examples 'meets ssh key restrictions' do
  where(:factory, :minimum, :result) do
    forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE

    [
      [:rsa_key_2048,       0, true],
      [:dsa_key_2048,       0, true],
      [:ecdsa_key_256,      0, true],
      [:ed25519_key_256,    0, true],
      [:ecdsa_sk_key_256,   0, true],
      [:ed25519_sk_key_256, 0, true],

      [:rsa_key_2048, 1024, true],
      [:rsa_key_2048, 2048, true],
      [:rsa_key_2048, 4096, false],

      [:dsa_key_2048, 1024, true],
      [:dsa_key_2048, 2048, true],
      [:dsa_key_2048, 4096, false],

      [:ecdsa_key_256, 256, true],
      [:ecdsa_key_256, 384, false],

      [:ed25519_key_256, 256, true],
      [:ed25519_key_256, 384, false],

      [:ecdsa_sk_key_256, 256, true],
      [:ecdsa_sk_key_256, 384, false],

      [:ed25519_sk_key_256, 256, true],
      [:ed25519_sk_key_256, 384, false],

      [:rsa_key_2048,       forbidden, false],
      [:dsa_key_2048,       forbidden, false],
      [:ecdsa_key_256,      forbidden, false],
      [:ed25519_key_256,    forbidden, false],
      [:ecdsa_sk_key_256,   forbidden, false],
      [:ed25519_sk_key_256, forbidden, false]
    ]
  end

  with_them do
    let(:ssh_key) { build(factory).key }
    let(:type) { Gitlab::SSHPublicKey.new(ssh_key).type }

    before do
      stub_application_setting("#{type}_key_restriction" => minimum)
    end

    it 'validates that the key is valid' do
      subject.key = ssh_key

      expect(subject.valid?).to eq(result)
    end
  end
end
