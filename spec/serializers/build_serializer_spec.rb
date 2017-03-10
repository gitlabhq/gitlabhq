require 'spec_helper'

describe BuildSerializer do
  let(:user) { create(:user) }

  let(:serializer) do
    described_class.new(user: user)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    # TODO:
  end

  describe '#represent_status' do
    context 'when represents only status' do
      let(:status) do
        Gitlab::Ci::Status::Success.new(double('object'), double('user'))
      end
      let(:resource) { create(:ci_build, status: :success) }

      subject { serializer.represent_status(resource) }

      it 'serializes only status' do
        expect(subject[:favicon]).to eq(status.favicon)
      end
    end
  end
end
