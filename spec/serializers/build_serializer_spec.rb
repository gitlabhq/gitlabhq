require 'spec_helper'

describe BuildSerializer do
  let(:user) { create(:user) }

  let(:serializer) do
    described_class.new(current_user: user)
  end

  subject { serializer.represent(resource) }

  describe '#represent' do
    context 'when a single object is being serialized' do
      let(:resource) { create(:ci_build) }

      it 'serializers the pipeline object' do
        expect(subject[:id]).to eq resource.id
      end
    end

    context 'when multiple objects are being serialized' do
      let(:resource) { create_list(:ci_build, 2) }

      it 'serializers the array of pipelines' do
        expect(subject).not_to be_empty
      end
    end
  end

  describe '#represent_status' do
    context 'for a failed build' do
      let(:resource) { create(:ci_build, :failed) }
      let(:status) { resource.detailed_status(double('user')) }

      subject { serializer.represent_status(resource) }

      it 'serializes only status' do
        expect(subject[:text]).to eq(status.text)
        expect(subject[:label]).to eq('failed')
        expect(subject[:tooltip]).to eq('failed <br> (unknown failure)')
        expect(subject[:icon]).to eq(status.icon)
        expect(subject[:favicon]).to match_asset_path("/assets/ci_favicons/#{status.favicon}.ico")
      end
    end

    context 'for any other type of build' do
      let(:resource) { create(:ci_build, :success) }
      let(:status) { resource.detailed_status(double('user')) }

      subject { serializer.represent_status(resource) }

      it 'serializes only status' do
        expect(subject[:text]).to eq(status.text)
        expect(subject[:label]).to eq('passed')
        expect(subject[:tooltip]).to eq('passed')
        expect(subject[:icon]).to eq(status.icon)
        expect(subject[:favicon]).to match_asset_path("/assets/ci_favicons/#{status.favicon}.ico")
      end
    end
  end
end
