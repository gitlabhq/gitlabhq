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
end
