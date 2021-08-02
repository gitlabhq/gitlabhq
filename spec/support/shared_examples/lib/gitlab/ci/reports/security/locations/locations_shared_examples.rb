# frozen_string_literal: true

RSpec.shared_examples 'vulnerability location' do
  describe '#initialize' do
    subject { described_class.new(**params) }

    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(**params)
      end
    end

    where(:param) do
      mandatory_params
    end

    with_them do
      context "when param #{params[:param]} is missing" do
        before do
          params.delete(param)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#fingerprint' do
    subject { described_class.new(**params).fingerprint }

    it "generates expected fingerprint" do
      expect(subject).to eq(expected_fingerprint)
    end
  end

  describe '#fingerprint_path' do
    subject { described_class.new(**params).fingerprint_path }

    it "generates expected fingerprint" do
      expect(subject).to eq(expected_fingerprint_path)
    end
  end

  describe '#==' do
    let(:location_1) { create(:ci_reports_security_locations_sast) }
    let(:location_2) { create(:ci_reports_security_locations_sast) }

    subject { location_1 == location_2 }

    it "returns true when fingerprints are equal" do
      allow(location_1).to receive(:fingerprint).and_return('fingerprint')
      allow(location_2).to receive(:fingerprint).and_return('fingerprint')

      expect(subject).to eq(true)
    end

    it "returns false when fingerprints are different" do
      allow(location_1).to receive(:fingerprint).and_return('fingerprint')
      allow(location_2).to receive(:fingerprint).and_return('another_fingerprint')

      expect(subject).to eq(false)
    end
  end
end
