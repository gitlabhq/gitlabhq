# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SSHPublicKey, lib: true do
  let(:key) { attributes_for(:rsa_key_2048)[:key] }
  let(:public_key) { described_class.new(key) }

  describe '.technology(name)' do
    it 'returns nil for an unrecognised name' do
      expect(described_class.technology(:foo)).to be_nil
    end

    where(:name) do
      [:rsa, :dsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
    end

    with_them do
      it { expect(described_class.technology(name).name).to eq(name) }
      it { expect(described_class.technology(name.to_s).name).to eq(name) }
    end
  end

  describe '.supported_types' do
    it 'returns array with the names of supported technologies' do
      expect(described_class.supported_types).to eq(
        [:rsa, :dsa, :ecdsa, :ed25519, :ecdsa_sk, :ed25519_sk]
      )
    end
  end

  describe '.supported_sizes(name)' do
    where(:name, :sizes) do
      [
        [:rsa, [1024, 2048, 3072, 4096]],
        [:dsa, [1024, 2048, 3072]],
        [:ecdsa, [256, 384, 521]],
        [:ed25519, [256]],
        [:ecdsa_sk, [256]],
        [:ed25519_sk, [256]]
      ]
    end

    with_them do
      it { expect(described_class.supported_sizes(name)).to eq(sizes) }
      it { expect(described_class.supported_sizes(name.to_s)).to eq(sizes) }
    end
  end

  describe '.supported_algorithms' do
    it 'returns all supported algorithms' do
      expect(described_class.supported_algorithms).to eq(
        %w(
        ssh-rsa
        ssh-dss
        ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521
        ssh-ed25519
        sk-ecdsa-sha2-nistp256@openssh.com
        sk-ssh-ed25519@openssh.com
        )
      )
    end
  end

  describe '.supported_algorithms_for_name' do
    where(:name, :algorithms) do
      [
        [:rsa, %w(ssh-rsa)],
        [:dsa, %w(ssh-dss)],
        [:ecdsa, %w(ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521)],
        [:ed25519, %w(ssh-ed25519)],
        [:ecdsa_sk, %w(sk-ecdsa-sha2-nistp256@openssh.com)],
        [:ed25519_sk, %w(sk-ssh-ed25519@openssh.com)]
      ]
    end

    with_them do
      it "returns all supported algorithms for #{params[:name]}" do
        expect(described_class.supported_algorithms_for_name(name)).to eq(algorithms)
        expect(described_class.supported_algorithms_for_name(name.to_s)).to eq(algorithms)
      end
    end
  end

  describe '.sanitize(key_content)' do
    let(:content) { build(:key).key }

    context 'when key has blank space characters' do
      it 'removes the extra blank space characters' do
        unsanitized = content.insert(100, "\n")
          .insert(40, "\r\n")
          .insert(30, ' ')

        sanitized = described_class.sanitize(unsanitized)
        _, body = sanitized.split

        expect(sanitized).not_to eq(unsanitized)
        expect(body).not_to match(/\s/)
      end
    end

    context "when key doesn't have blank space characters" do
      it "doesn't modify the content" do
        sanitized = described_class.sanitize(content)

        expect(sanitized).to eq(content)
      end
    end

    context "when key is invalid" do
      it 'returns the original content' do
        unsanitized = "ssh-foo any content=="
        sanitized = described_class.sanitize(unsanitized)

        expect(sanitized).to eq(unsanitized)
      end
    end
  end

  describe '#valid?' do
    subject { public_key }

    context 'with a valid SSH key' do
      where(:factory) do
        %i(rsa_key_2048
           rsa_key_4096
           rsa_key_5120
           rsa_key_8192
           dsa_key_2048
           ecdsa_key_256
           ed25519_key_256
           ecdsa_sk_key_256
           ed25519_sk_key_256)
      end

      with_them do
        let(:key) { attributes_for(factory)[:key] }

        it { is_expected.to be_valid }

        context 'when key begins with options' do
          let(:key) { "restrict,command='dump /home' #{attributes_for(factory)[:key]}" }

          it { is_expected.to be_valid }
        end

        context 'when key is in known_hosts format' do
          context "when key begins with 'example.com'" do
            let(:key) { "example.com #{attributes_for(factory)[:key]}" }

            it { is_expected.to be_valid }
          end

          context "when key begins with '@revoked other.example.com'" do
            let(:key) { "@revoked other.example.com #{attributes_for(factory)[:key]}" }

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.not_to be_valid }
    end

    context 'when an unsupported SSH key algorithm' do
      let(:key) { "unsupported-#{attributes_for(:rsa_key_2048)[:key]}" }

      it { is_expected.not_to be_valid }
    end
  end

  shared_examples 'raises error when the key is represented by a class that is not in the list of supported technologies' do
    context 'when the key is represented by a class that is not in the list of supported technologies' do
      it 'raises error' do
        klass = Class.new
        key = klass.new

        allow(public_key).to receive(:key).and_return(key)

        expect { subject }.to raise_error("Unsupported key type: #{key.class}")
      end
    end

    context 'when the key is represented by a subclass of the class that is in the list of supported technologies' do
      it 'raises error' do
        rsa_subclass = Class.new(described_class.technology(:rsa).key_class) do
          def initialize
          end
        end

        key = rsa_subclass.new

        allow(public_key).to receive(:key).and_return(key)

        expect { subject }.to raise_error("Unsupported key type: #{key.class}")
      end
    end
  end

  describe '#type' do
    subject { public_key.type }

    where(:factory, :type) do
      [
        [:rsa_key_2048, :rsa],
        [:dsa_key_2048, :dsa],
        [:ecdsa_key_256, :ecdsa],
        [:ed25519_key_256, :ed25519],
        [:ecdsa_sk_key_256, :ecdsa_sk],
        [:ed25519_sk_key_256, :ed25519_sk]
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(type) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end

    include_examples 'raises error when the key is represented by a class that is not in the list of supported technologies'
  end

  describe '#bits' do
    subject { public_key.bits }

    where(:factory, :bits) do
      [
        [:rsa_key_2048, 2048],
        [:rsa_key_4096, 4096],
        [:rsa_key_5120, 5120],
        [:rsa_key_8192, 8192],
        [:dsa_key_2048, 2048],
        [:ecdsa_key_256, 256],
        [:ed25519_key_256, 256],
        [:ecdsa_sk_key_256, 256],
        [:ed25519_sk_key_256, 256]
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(bits) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end

    include_examples 'raises error when the key is represented by a class that is not in the list of supported technologies'
  end

  describe '#fingerprint' do
    subject { public_key.fingerprint }

    where(:factory, :fingerprint) do
      [
        [:rsa_key_2048, '58:a8:9d:cd:1f:70:f8:5a:d9:e4:24:8e:da:89:e4:fc'],
        [:rsa_key_4096, 'df:73:db:29:3c:a5:32:cf:09:17:7e:8e:9d:de:d7:f7'],
        [:rsa_key_5120, 'fe:fa:3a:4d:7d:51:ec:bf:c7:64:0c:96:d0:17:8a:d0'],
        [:rsa_key_8192, 'fb:53:7f:e9:2f:f7:17:aa:c8:32:52:06:8e:05:e2:82'],
        [:dsa_key_2048, 'c8:85:1e:df:44:0f:20:00:3c:66:57:2b:21:10:5a:27'],
        [:ecdsa_key_256, '67:a3:a9:7d:b8:e1:15:d4:80:40:21:34:bb:ed:97:38'],
        [:ed25519_key_256, 'e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73'],
        [:ecdsa_sk_key_256, '56:b9:bc:99:3d:2f:cf:63:6b:70:d8:f9:40:7e:09:4c'],
        [:ed25519_sk_key_256, 'f9:a0:64:0b:4b:72:72:0e:62:92:d7:04:14:74:1c:c9']
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(fingerprint) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end
  end

  describe '#fingerprint_sha256' do
    subject { public_key.fingerprint_sha256 }

    where(:factory, :fingerprint_sha256) do
      [
        [:rsa_key_2048, 'SHA256:GdtgO0eHbwLB+mK47zblkoXujkqKRZjgMQrHH6Kks3E'],
        [:rsa_key_4096, 'SHA256:ByDU7hQ1JB95l6p53rHrffc4eXvEtqGUtQhS+Dhyy7g'],
        [:rsa_key_5120, 'SHA256:PCCupLbFHScm4AbEufbGDvhBU27IM0MVAor715qKQK8'],
        [:rsa_key_8192, 'SHA256:CtHFQAS+9Hb8z4vrv4gVQPsHjNN0WIZhWODaB1mQLs4'],
        [:dsa_key_2048, 'SHA256:+a3DQ7cU5GM+gaYOfmc0VWNnykHQSuth3VRcCpWuYNI'],
        [:ecdsa_key_256, 'SHA256:C+I5k3D+IGeM6k5iBR1ZsphqTKV+7uvL/XZ5hcrTr7g'],
        [:ed25519_key_256, 'SHA256:DCKAjzxWrdOTjaGKBBjtCW8qY5++GaiAJflrHPmp6W0'],
        [:ecdsa_sk_key_256, 'SHA256:N0sNKBgWKK8usPuPegtgzHQQA9vQ/dRhAEhwFDAnLA4'],
        [:ed25519_sk_key_256, 'SHA256:U8IKRkIHed6vFMTflwweA3HhIf2DWgZ8EFTm9fgwOUk']
      ]
    end

    with_them do
      let(:key) { attributes_for(factory)[:key] }

      it { is_expected.to eq(fingerprint_sha256) }
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.to be_nil }
    end
  end

  describe '#key_text' do
    where(:key_value) do
      [
        'this is not a key',
        nil
      ]
    end

    with_them do
      let(:key) { key_value }

      it 'carries the unmodified key data' do
        expect(public_key.key_text).to eq(key)
      end
    end
  end
end
