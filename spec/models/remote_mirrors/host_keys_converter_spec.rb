# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrors::HostKeysConverter, feature_category: :source_code_management do
  describe '#to_ssh_known_hosts!' do
    subject(:to_ssh_known_hosts!) { described_class.new(host_keys, url: url).to_ssh_known_hosts! }

    using RSpec::Parameterized::TableSyntax

    let(:default_url) { 'ssh://git@example.com/org/repo.git' }
    let(:nil_url) { nil }
    let(:ssh_ed25519_key) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' }
    let(:ecdsa_key) do
      # rubocop:disable Layout/LineLength -- SSH key format requires long lines
      'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY='
      # rubocop:enable Layout/LineLength
    end

    # rubocop:disable Layout/LineLength -- SSH key format requires long lines
    let(:ssh_rsa_key) { 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLIp+4ciR2YO9f9rpldc7InNQw/TBUtcNbJ2XR0rr15/5ytz7YM16xXG0Qjx576PNSmqs4gbTrvTuFZak+v1Jx/9deHRq/yqp9f+tv33+iaJGCQCX/+OVY7aWgV2R9YsS7XQ4mnv4XlOTEssib/rGAIT+ATd/GcdYSEOO+dh4O09/6O/jIMGSeP+NNetgn1nPCnLOjrXFZUnUtNDi6EEKeIlrliJjSb7Jr4f7gjvZnv4RskWHHFo8FgAAqt0gOMT6EmKrnypBe2vLGSAXbtkXr01q6/DNPH+n9VA1LTV6v1KN/W5CN5tQV11wRSKiM8g5OEbi86VjJRi2sOuYoXQU1' }
    # rubocop:enable Layout/LineLength
    let(:bare_ed25519) { [ssh_ed25519_key] }

    context 'with successful conversion' do
      let(:port_22_url)   { 'ssh://git@example.com:22/org/repo.git' }
      let(:port_2222_url) { 'ssh://git@example.com:2222/org/repo.git' }

      let(:bare_ecdsa)          { [ecdsa_key] }
      let(:bare_rsa)            { [ssh_rsa_key] }
      let(:full_known_hosts)    { ["mirror.example.org #{ssh_ed25519_key}"] }
      let(:multiple_keys)       { [ssh_ed25519_key, ecdsa_key] }
      let(:mixed_formats)       { ["mirror.example.org #{ssh_ed25519_key}", ecdsa_key] }
      let(:blank_keys_mixed)    { [ssh_ed25519_key, '', '  ', nil] }
      let(:whitespace_padded)   { ["  #{ssh_ed25519_key}  "] }
      let(:hostname_with_comma) { ["example.com,93.184.216.34 #{ssh_ed25519_key}"] }
      let(:form_encoded)        { [ssh_rsa_key.tr('+', ' ')] }

      let(:ed25519_result)      { "example.com #{ssh_ed25519_key}" }
      let(:ecdsa_result)        { "example.com #{ecdsa_key}" }
      let(:rsa_result)          { "example.com #{ssh_rsa_key}" }
      let(:known_hosts_result)  { "mirror.example.org #{ssh_ed25519_key}" }
      let(:multiple_result)     { "example.com #{ssh_ed25519_key}\nexample.com #{ecdsa_key}" }
      let(:mixed_result)        { "mirror.example.org #{ssh_ed25519_key}\nexample.com #{ecdsa_key}" }
      let(:comma_result)        { "example.com,93.184.216.34 #{ssh_ed25519_key}" }
      let(:port_result)         { "[example.com]:2222 #{ssh_ed25519_key}" }

      # -- parameterized table formatting
      where(:description, :url, :host_keys, :expected) do
        'bare ed25519 key'              | ref(:default_url)   | ref(:bare_ed25519)        | ref(:ed25519_result)
        'bare ecdsa key'                | ref(:default_url)   | ref(:bare_ecdsa)          | ref(:ecdsa_result)
        'bare rsa key'                  | ref(:default_url)   | ref(:bare_rsa)            | ref(:rsa_result)
        'full known_hosts format'       | ref(:default_url)   | ref(:full_known_hosts)    | ref(:known_hosts_result)
        'multiple keys'                 | ref(:default_url)   | ref(:multiple_keys)       | ref(:multiple_result)
        'mixed formats'                 | ref(:default_url)   | ref(:mixed_formats)       | ref(:mixed_result)
        'blank keys filtered out'       | ref(:default_url)   | ref(:blank_keys_mixed)    | ref(:ed25519_result)
        'whitespace stripped'           | ref(:default_url)   | ref(:whitespace_padded)   | ref(:ed25519_result)
        'hostname with comma preserved' | ref(:default_url)   | ref(:hostname_with_comma) | ref(:comma_result)
        'form-encoded + restored'       | ref(:default_url)   | ref(:form_encoded)        | ref(:rsa_result)
        'standard port omitted'         | ref(:port_22_url)   | ref(:bare_ed25519)        | ref(:ed25519_result)
        'non-standard port bracketed'   | ref(:port_2222_url) | ref(:bare_ed25519)        | ref(:port_result)
        'nil URL with full format keys' | ref(:nil_url)       | ref(:full_known_hosts)    | ref(:known_hosts_result)
      end
      with_them do
        it 'returns expected result' do
          is_expected.to eq(expected)
        end
      end
    end

    context 'with empty host_keys' do
      let(:url) { default_url }
      let(:host_keys) { [] }

      it { is_expected.to be_nil }
    end

    context 'with nil host_keys' do
      let(:url) { default_url }
      let(:host_keys) { nil }

      it { is_expected.to be_nil }
    end

    context 'with invalid input' do
      let(:garbage_keys)       { ['invalid_key'] }
      let(:garbage_expected)   { ['invalid_key'] }
      let(:corrupted_keys)     { ['ssh-ed25519 invalid_base64'] }
      let(:corrupted_expected) { ['ssh-ed25519 invalid_base64'] }
      let(:mixed_keys)         { [ssh_ed25519_key, 'invalid_key'] }
      let(:mixed_expected)     { ['invalid_key'] }
      let(:too_many_keys)      { Array.new(11, ssh_ed25519_key) }
      let(:too_many_expected)  { ['too many host keys (maximum is 10)'] }
      let(:unparseable_url)    { 'not a valid url' }
      let(:invalid_uri_url)    { 'ssh://git@exam ple.com/repo.git' }
      let(:hostname_error)     { ['cannot determine hostname from URL for bare key'] }

      # -- parameterized table formatting
      where(:description, :url, :host_keys, :expected_invalid) do
        'garbage string'          | ref(:default_url)     | ref(:garbage_keys)   | ref(:garbage_expected)
        'corrupted base64'        | ref(:default_url)     | ref(:corrupted_keys) | ref(:corrupted_expected)
        'mixed valid and invalid' | ref(:default_url)     | ref(:mixed_keys)     | ref(:mixed_expected)
        'too many keys'           | ref(:default_url)     | ref(:too_many_keys)  | ref(:too_many_expected)
        'nil URL with bare keys'  | ref(:nil_url)         | ref(:bare_ed25519)   | ref(:hostname_error)
        'unparseable hostname'    | ref(:unparseable_url) | ref(:bare_ed25519)   | ref(:hostname_error)
        'invalid URI'             | ref(:invalid_uri_url) | ref(:bare_ed25519)   | ref(:hostname_error)
      end
      with_them do
        it 'raises InvalidHostKeyError with the invalid keys' do
          expect { to_ssh_known_hosts! }.to raise_error(described_class::InvalidHostKeyError) do |error|
            expect(error.invalid_keys).to eq(expected_invalid)
          end
        end
      end
    end
  end
end
