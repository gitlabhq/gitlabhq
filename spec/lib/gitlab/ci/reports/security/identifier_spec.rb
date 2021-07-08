# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Identifier do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize' do
    subject { described_class.new(**params) }

    let(:params) do
      {
        external_type: 'brakeman_warning_code',
        external_id: '107',
        name: 'Brakeman Warning Code 107',
        url: 'https://brakemanscanner.org/docs/warning_types/cross_site_scripting/'
      }
    end

    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          external_type: 'brakeman_warning_code',
          external_id: '107',
          fingerprint: 'aa2254904a69148ad14b6ac5db25b355da9c987f',
          name: 'Brakeman Warning Code 107',
          url: 'https://brakemanscanner.org/docs/warning_types/cross_site_scripting/'
        )
      end
    end

    %i[external_type external_id name].each do |attribute|
      context "when attribute #{attribute} is missing" do
        before do
          params.delete(attribute)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#key' do
    let(:identifier) { create(:ci_reports_security_identifier) }

    subject { identifier.key }

    it 'returns fingerprint' do
      is_expected.to eq(identifier.fingerprint)
    end
  end

  describe '#type_identifier?' do
    where(:external_type, :expected_result) do
      'cve'  | false
      'foo'  | false
      'cwe'  | true
      'wasc' | true
    end

    with_them do
      let(:identifier) { create(:ci_reports_security_identifier, external_type: external_type) }

      subject { identifier.type_identifier? }

      it { is_expected.to be(expected_result) }
    end
  end

  describe 'external type check methods' do
    where(:external_type, :is_cve?, :is_cwe?, :is_wasc?) do
      'Foo'  | false | false | false
      'Cve'  | true  | false | false
      'Cwe'  | false | true  | false
      'Wasc' | false | false | true
    end

    with_them do
      let(:identifier) { create(:ci_reports_security_identifier, external_type: external_type) }

      it 'returns correct result for the type check method' do
        expect(identifier.cve?).to be(is_cve?)
        expect(identifier.cwe?).to be(is_cwe?)
        expect(identifier.wasc?).to be(is_wasc?)
      end
    end
  end

  describe '#to_hash' do
    let(:identifier) { create(:ci_reports_security_identifier) }

    subject { identifier.to_hash }

    it 'returns expected hash' do
      is_expected.to eq({
        external_type: identifier.external_type,
        external_id: identifier.external_id,
        fingerprint: identifier.fingerprint,
        name: identifier.name,
        url: identifier.url
      })
    end
  end

  describe '#==' do
    where(:type_1, :id_1, :type_2, :id_2, :equal, :case_name) do
      'CVE' | '2018-1234' | 'CVE'           | '2018-1234' | true  | 'when external_type and external_id are equal'
      'CVE' | '2018-1234' | 'brakeman_code' | '2018-1234' | false | 'when external_type is different'
      'CVE' | '2018-1234' | 'CVE'           | '2019-6789' | false | 'when external_id is different'
    end

    with_them do
      let(:identifier_1) { create(:ci_reports_security_identifier, external_type: type_1, external_id: id_1) }
      let(:identifier_2) { create(:ci_reports_security_identifier, external_type: type_2, external_id: id_2) }

      it "returns #{params[:equal]}" do
        expect(identifier_1 == identifier_2).to eq(equal)
      end
    end
  end
end
