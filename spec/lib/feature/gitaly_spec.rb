require 'spec_helper'

describe Feature::Gitaly do
  let(:feature_flag) { "mep_mep" }

  before do
    stub_const("#{described_class}::SERVER_FEATURE_FLAGS", [feature_flag])
  end

  describe ".enabled?" do
    context 'when the gate is closed' do
      before do
        stub_feature_flags(gitaly_mep_mep: false)
      end

      it 'returns false' do
        expect(described_class.enabled?(feature_flag)).to be(false)
      end
    end

    context 'when the flag defaults to on' do
      it 'returns true' do
        expect(described_class.enabled?(feature_flag)).to be(true)
      end
    end
  end

  describe ".server_feature_flags" do
    context 'when one flag is disabled' do
      before do
        stub_feature_flags(gitaly_mep_mep: false)
      end

      subject { described_class.server_feature_flags }

      it { is_expected.to be_a(Hash) }
      it { is_expected.to eq("gitaly-feature-mep-mep" => "false") }
    end
  end
end
