# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::FileEntry, type: :model do
  let_it_be(:package_file) { create(:debian_package_file, :dsc) }

  let(:filename) { 'sample_1.2.3~alpha2.dsc' }
  let(:size) { 671 }
  let(:md5sum) { '3b0817804f669e16cdefac583ad88f0e' }
  let(:section) { 'libs' }
  let(:priority) { 'optional' }
  let(:sha1sum) { '32ecbd674f0bfd310df68484d87752490685a8d6' }
  let(:sha256sum) { '844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba' }

  let(:file_entry) do
    described_class.new(
      filename: filename,
      size: size,
      md5sum: md5sum,
      section: section,
      priority: priority,
      sha1sum: sha1sum,
      sha256sum: sha256sum,
      package_file: package_file
    )
  end

  subject { file_entry }

  describe 'validations' do
    it { is_expected.to be_valid }

    describe '#filename' do
      it { is_expected.to validate_presence_of(:filename) }
      it { is_expected.not_to allow_value('Hé').for(:filename) }
    end

    describe '#size' do
      it { is_expected.to validate_presence_of(:size) }
    end

    describe '#md5sum' do
      it { is_expected.to validate_presence_of(:md5sum) }
      it { is_expected.not_to allow_value('12345678901234567890123456789012').for(:md5sum).with_message('mismatch for sample_1.2.3~alpha2.dsc: 3b0817804f669e16cdefac583ad88f0e != 12345678901234567890123456789012') }
    end

    describe '#section' do
      it { is_expected.to validate_presence_of(:section) }
    end

    describe '#priority' do
      it { is_expected.to validate_presence_of(:priority) }
    end

    describe '#sha1sum' do
      it { is_expected.to validate_presence_of(:sha1sum) }
      it { is_expected.not_to allow_value('1234567890123456789012345678901234567890').for(:sha1sum).with_message('mismatch for sample_1.2.3~alpha2.dsc: 32ecbd674f0bfd310df68484d87752490685a8d6 != 1234567890123456789012345678901234567890') }
    end

    describe '#sha256sum' do
      it { is_expected.to validate_presence_of(:sha256sum) }
      it { is_expected.not_to allow_value('1234567890123456789012345678901234567890123456789012345678901234').for(:sha256sum).with_message('mismatch for sample_1.2.3~alpha2.dsc: 844f79825b7e8aaa191e514b58a81f9ac1e58e2180134b0c9512fa66d896d7ba != 1234567890123456789012345678901234567890123456789012345678901234') }
    end

    describe '#package_file' do
      it { is_expected.to validate_presence_of(:package_file) }
    end
  end

  describe '#component' do
    subject { file_entry.component }

    context 'without section' do
      let(:section) { nil }

      it { is_expected.to eq 'main' }
    end

    context 'with empty section' do
      let(:section) { '' }

      it { is_expected.to eq 'main' }
    end

    context 'with ruby section' do
      let(:section) { 'ruby' }

      it { is_expected.to eq 'main' }
    end

    context 'with contrib/ruby section' do
      let(:section) { 'contrib/ruby' }

      it { is_expected.to eq 'contrib' }
    end
  end
end
