# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Link do
  subject(:security_link) { described_class.new(name: 'CVE-2020-0202', url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0202') }

  describe '#initialize' do
    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          name: 'CVE-2020-0202',
          url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0202'
        )
      end
    end

    describe '#to_hash' do
      it 'returns expected hash' do
        expect(security_link.to_hash).to eq(
          {
            name: 'CVE-2020-0202',
            url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2020-0202'
          }
        )
      end
    end
  end

  describe '#==' do
    let(:link) { described_class.new(name: 'CVE-2020-0202', url: 'https://example.com') }

    context 'when name and url match' do
      let(:other) { described_class.new(name: 'CVE-2020-0202', url: 'https://example.com') }

      it 'is equal' do
        expect(link).to eq(other)
      end
    end

    context 'when name or url differs' do
      let(:other) { described_class.new(name: 'CVE-2020-0202', url: 'https://different.example.com') }

      it 'is not equal' do
        expect(link).not_to eq(other)
      end
    end

    context 'when the other object is not a link' do
      it 'is not equal instead of raising' do
        expect(link).not_to eq('not a link')
      end
    end
  end
end
