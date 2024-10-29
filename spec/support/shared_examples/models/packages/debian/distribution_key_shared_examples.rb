# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'Debian Distribution Key' do |container|
  let_it_be_with_refind(:distribution_key) { create("debian_#{container}_distribution_key") }

  subject { distribution_key }

  describe 'relationships' do
    it { is_expected.to belong_to(:distribution).class_name("Packages::Debian::#{container.capitalize}Distribution").inverse_of(:key) }
  end

  describe 'validations' do
    describe "#distribution" do
      it { is_expected.to validate_presence_of(:distribution) }
    end

    describe '#private_key' do
      it { is_expected.to validate_presence_of(:private_key) }

      it { is_expected.to allow_value("-----BEGIN PGP PRIVATE KEY BLOCK-----\n...").for(:private_key) }
      it { is_expected.not_to allow_value('A').for(:private_key).with_message('must be ASCII armored') }
    end

    describe '#passphrase' do
      it { is_expected.to validate_presence_of(:passphrase) }

      it { is_expected.to allow_value('P@$$w0rd').for(:passphrase) }
      it { is_expected.to allow_value('A' * 255).for(:passphrase) }
      it { is_expected.not_to allow_value('A' * 256).for(:passphrase) }
    end

    describe '#public_key' do
      it { is_expected.to validate_presence_of(:public_key) }

      it { is_expected.to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\n...").for(:public_key) }
      it { is_expected.not_to allow_value('A').for(:public_key).with_message('must be ASCII armored') }
    end

    describe '#fingerprint' do
      it { is_expected.to validate_presence_of(:passphrase) }

      it { is_expected.to allow_value('abc').for(:passphrase) }
      it { is_expected.to allow_value('A' * 255).for(:passphrase) }
      it { is_expected.not_to allow_value('A' * 256).for(:passphrase) }
    end
  end
end
