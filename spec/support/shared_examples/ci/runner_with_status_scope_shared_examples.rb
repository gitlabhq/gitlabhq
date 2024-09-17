# frozen_string_literal: true

RSpec.shared_examples 'runner with status scope' do
  describe '.with_status' do
    subject(:scope) { described_class.with_status(status) }

    described_class::AVAILABLE_STATUSES_INCL_DEPRECATED.each do |status|
      context "with #{status} status" do
        let(:status) { status }

        it "calls corresponding :#{status} scope" do
          expect(described_class).to receive(status.to_sym).and_call_original

          scope
        end
      end
    end

    context 'with invalid status' do
      let(:status) { :invalid_status }

      it 'returns all records' do
        expect(described_class).to receive(:all).at_least(:once).and_call_original

        expect { scope }.not_to raise_error
      end
    end
  end
end
