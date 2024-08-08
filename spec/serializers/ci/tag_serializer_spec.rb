# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TagSerializer, feature_category: :continuous_integration do
  let_it_be(:user) { build_stubbed(:user) }

  let(:serializer) do
    described_class.new(current_user: user)
  end

  subject(:data) { serializer.represent(resource) }

  describe '#represent' do
    context 'when a single object is being serialized' do
      let(:resource) { build_stubbed(:ci_tag) }

      it 'serializers the tag object' do
        expect(data).to include(id: resource.id, name: resource.name)
      end
    end

    context 'when multiple objects are being serialized' do
      let(:resource) { create_pair(:ci_tag) }

      it 'serializers the array of tags' do
        expect(data).to contain_exactly(
          a_hash_including(id: resource.first.id),
          a_hash_including(id: resource.last.id)
        )
      end
    end
  end
end
