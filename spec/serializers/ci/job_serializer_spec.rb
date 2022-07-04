# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobSerializer do
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
end
