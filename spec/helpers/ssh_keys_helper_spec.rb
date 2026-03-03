# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SshKeysHelper, feature_category: :system_access do
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

    it 'excludes ecdsa algorithms below the minimum key size restriction' do
      stub_application_setting(ecdsa_key_restriction: 521)

      result = ssh_key_allowed_algorithms
      expect(result).not_to include("'ecdsa-sha2-nistp256'")
      expect(result).not_to include("'ecdsa-sha2-nistp384'")
      expect(result).to include("'ecdsa-sha2-nistp521'")
      # ecdsa_sk is a separate key type and should not be affected
      expect(result).to include("sk-ecdsa-sha2-nistp256@openssh.com")
    end

    it 'includes all ecdsa algorithms when no minimum size is set' do
      stub_application_setting(ecdsa_key_restriction: 0)

      result = ssh_key_allowed_algorithms
      expect(result).to include("'ecdsa-sha2-nistp256'")
      expect(result).to include("'ecdsa-sha2-nistp384'")
      expect(result).to include("'ecdsa-sha2-nistp521'")
    end

    it 'excludes ecdsa algorithms below 384-bit restriction' do
      stub_application_setting(ecdsa_key_restriction: 384)

      result = ssh_key_allowed_algorithms
      expect(result).not_to include("'ecdsa-sha2-nistp256'")
      expect(result).to include("'ecdsa-sha2-nistp384'")
      expect(result).to include("'ecdsa-sha2-nistp521'")
    end

    it 'still includes rsa algorithm when minimum key size is set' do
      stub_application_setting(rsa_key_restriction: 4096)

      result = ssh_key_allowed_algorithms
      expect(result).to include("'ssh-rsa'")
    end
  end
end
