require 'spec_helper'

describe Feature::Gitaly do
  let(:feature_flag) { "mepmep" }

  describe ".enabled?" do
    context 'when the gate is closed' do
      before do
        allow(Feature).to receive(:enabled?).with("gitaly_mepmep").and_return(false)
      end

      it 'returns false' do
        expect(described_class.enabled?(feature_flag)).to be(false)
      end
    end
  end

  describe ".server_feature_flags" do
    before do
      stub_const("#{described_class}::SERVER_FEATURE_FLAGS", [feature_flag])
      allow(Feature).to receive(:enabled?).with("gitaly_mepmep").and_return(false)
    end

    subject { described_class.server_feature_flags }

    it { is_expected.to be_a(Hash) }

    context 'when one flag is disabled' do
      it { is_expected.to eq("gitaly-feature-mepmep" => "false") }
    end
  end
end
