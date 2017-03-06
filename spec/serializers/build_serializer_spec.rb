require 'spec_helper'

describe BuildSerializer do
  let(:user) { create(:user) }

  let(:serializer) do
    described_class.new(user: user)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'when used with status' do
      let(:serializer) do
        described_class.new(user: user)
          .with_status
      end
      let(:resource) { create(:ci_build) }

      it 'serializes only status' do
        expect(subject[:details][:status]).not_to be_empty
        expect(subject[:details].keys.count).to eq 1
      end
    end
  end
end
