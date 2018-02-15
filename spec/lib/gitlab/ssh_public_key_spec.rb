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

  describe '#valid?' do
    subject { public_key }

    context 'with a valid SSH key' do
      it { is_expected.to be_valid }
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
        [:rsa_key_2048, '2e:ca:dc:e0:37:29:ed:fc:f0:1d:bf:66:d4:cd:51:b1'],
        [:dsa_key_2048, 'bc:c1:a4:be:7e:8c:84:56:b3:58:93:53:c6:80:78:8c'],
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
