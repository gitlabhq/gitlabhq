# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SshKeysHelper do
  describe '#ssh_key_allowed_algorithms' do
    it 'returns string with the names of allowed algorithms that are quoted and joined by commas' do
      allowed_algorithms = Gitlab::CurrentSettings.allowed_key_types.flat_map do |ssh_key_type_name|
        Gitlab::SSHPublicKey.supported_algorithms_for_name(ssh_key_type_name)
      end

      quoted_allowed_algorithms = allowed_algorithms.map { |name| "'#{name}'" }

      expected_string = Gitlab::Sentence.to_exclusive_sentence(quoted_allowed_algorithms)

      expect(ssh_key_allowed_algorithms).to eq(expected_string)
    end

    it 'returns only allowed algorithms' do
      expect(ssh_key_allowed_algorithms).to match('rsa')
      stub_application_setting(rsa_key_restriction: ApplicationSetting::FORBIDDEN_KEY_VALUE)
      expect(ssh_key_allowed_algorithms).not_to match('rsa')
    end
  end
end
