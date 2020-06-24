# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsDownloadObject do
  let(:oid) { 'cd293be6cea034bd45a0352775a219ef5dc7825ce55d1f7dae9762d80ce64411' }
  let(:link) { 'http://www.example.com' }
  let(:size) { 1 }

  subject { described_class.new(oid: oid, size: size, link: link) }

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:size).is_greater_than_or_equal_to(0) }

    context 'oid attribute' do
      it 'must be 64 characters long' do
        aggregate_failures do
          expect(described_class.new(oid: 'a' * 63, size: size, link: link)).to be_invalid
          expect(described_class.new(oid: 'a' * 65, size: size, link: link)).to be_invalid
          expect(described_class.new(oid: 'a' * 64, size: size, link: link)).to be_valid
        end
      end

      it 'must contain only hexadecimal characters' do
        aggregate_failures do
          expect(subject).to be_valid
          expect(described_class.new(oid: 'g' * 64, size: size, link: link)).to be_invalid
        end
      end
    end

    context 'link attribute' do
      it 'only http and https protocols are valid' do
        aggregate_failures do
          expect(described_class.new(oid: oid, size: size, link: 'http://www.example.com')).to be_valid
          expect(described_class.new(oid: oid, size: size, link: 'https://www.example.com')).to be_valid
          expect(described_class.new(oid: oid, size: size, link: 'ftp://www.example.com')).to be_invalid
          expect(described_class.new(oid: oid, size: size, link: 'ssh://www.example.com')).to be_invalid
          expect(described_class.new(oid: oid, size: size, link: 'git://www.example.com')).to be_invalid
        end
      end

      it 'cannot be empty' do
        expect(described_class.new(oid: oid, size: size, link: '')).not_to be_valid
      end

      context 'when localhost or local network addresses' do
        subject { described_class.new(oid: oid, size: size, link: 'http://192.168.1.1') }

        before do
          allow(ApplicationSetting)
            .to receive(:current)
              .and_return(ApplicationSetting.build_from_defaults(allow_local_requests_from_web_hooks_and_services: setting))
        end

        context 'are allowed' do
          let(:setting) { true }

          it { expect(subject).to be_valid }
        end

        context 'are not allowed' do
          let(:setting) { false }

          it { expect(subject).to be_invalid }
        end
      end
    end
  end
end
