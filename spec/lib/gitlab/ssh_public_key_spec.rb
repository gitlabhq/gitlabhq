require 'spec_helper'

describe Gitlab::SSHPublicKey, lib: true do
  let(:key) { attributes_for(:rsa_key_2048)[:key] }
  let(:public_key) { described_class.new(key) }

  describe '.technology(name)' do
    it 'returns nil for an unrecognised name' do
      expect(described_class.technology(:foo)).to be_nil
    end

    where(:name) do
      [:rsa, :dsa, :ecdsa, :ed25519]
    end

    with_them do
      it { expect(described_class.technology(name).name).to eq(name) }
      it { expect(described_class.technology(name.to_s).name).to eq(name) }
    end
  end

  describe '.supported_sizes(name)' do
    where(:name, :sizes) do
      [
        [:rsa, [1024, 2048, 3072, 4096]],
        [:dsa, [1024, 2048, 3072]],
        [:ecdsa, [256, 384, 521]],
        [:ed25519, [256]]
      ]
    end

    subject { described_class.supported_sizes(name) }

    with_them do
      it { expect(described_class.supported_sizes(name)).to eq(sizes) }
      it { expect(described_class.supported_sizes(name.to_s)).to eq(sizes) }
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
           ed25519_key_256)
      end

      with_them do
        let(:key) { attributes_for(factory)[:key] }

        it { is_expected.to be_valid }
      end
    end

    context 'with an invalid SSH key' do
      let(:key) { 'this is not a key' }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#type' do
    subject { public_key.type }

    where(:factory, :type) do
      [
        [:rsa_key_2048, :rsa],
        [:dsa_key_2048, :dsa],
        [:ecdsa_key_256, :ecdsa],
        [:ed25519_key_256, :ed25519]
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
        [:ed25519_key_256, 256]
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
        [:ed25519_key_256, 'e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73']
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

  describe '#key_text' do
    let(:key) { 'this is not a key' }

    it 'carries the unmodified key data' do
      expect(public_key.key_text).to eq(key)
    end
  end
end
