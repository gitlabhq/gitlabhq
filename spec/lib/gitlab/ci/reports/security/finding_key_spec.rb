# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::FindingKey do
  using RSpec::Parameterized::TableSyntax

  describe '#==' do
    context 'when the comparison is done between FindingKey instances' do
      where(:location_fp_1, :location_fp_2, :identifier_fp_1, :identifier_fp_2, :equals?) do
        nil           | 'different location fp' | 'identifier fp' | 'different identifier fp' | false
        'location fp' | nil                     | 'identifier fp' | 'different identifier fp' | false
        'location fp' | 'different location fp' | nil             | 'different identifier fp' | false
        'location fp' | 'different location fp' | 'identifier fp' | nil                       | false
        nil           | nil                     | 'identifier fp' | 'identifier fp'           | false
        'location fp' | 'location fp'           | nil             | nil                       | false
        nil           | nil                     | nil             | nil                       | false
        'location fp' | 'different location fp' | 'identifier fp' | 'different identifier fp' | false
        'location fp' | 'different location fp' | 'identifier fp' | 'identifier fp'           | false
        'location fp' | 'location fp'           | 'identifier fp' | 'different identifier fp' | false
        'location fp' | 'location fp'           | 'identifier fp' | 'identifier fp'           | true
      end

      with_them do
        let(:finding_key_1) do
          build(
            :ci_reports_security_finding_key,
            location_fingerprint: location_fp_1,
            identifier_fingerprint: identifier_fp_1
          )
        end

        let(:finding_key_2) do
          build(
            :ci_reports_security_finding_key,
            location_fingerprint: location_fp_2,
            identifier_fingerprint: identifier_fp_2
          )
        end

        subject { finding_key_1 == finding_key_2 }

        it { is_expected.to be(equals?) }
      end
    end

    context 'when the comparison is not done between FindingKey instances' do
      let(:finding_key) { build(:ci_reports_security_finding_key) }
      let(:uuid) { SecureRandom.uuid }

      subject { finding_key == uuid }

      it { is_expected.to be_falsey }
    end
  end
end
