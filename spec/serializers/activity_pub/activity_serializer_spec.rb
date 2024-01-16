# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ActivitySerializer, feature_category: :integrations do
  let(:implementer_class) do
    Class.new(described_class)
  end

  let(:serializer) { implementer_class.new.represent(resource) }

  let(:resource) { build_stubbed(:release) }

  let(:transitive_entity_class) do
    Class.new(Grape::Entity) do
      expose :id do |*|
        'https://example.com/unique/url'
      end

      expose :type do |*|
        'Follow'
      end

      expose :actor do |*|
        'https://example.com/actor/alice'
      end

      expose :object do |*|
        'https://example.com/actor/bob'
      end
    end
  end

  let(:intransitive_entity_class) do
    Class.new(Grape::Entity) do
      expose :id do |*|
        'https://example.com/unique/url'
      end

      expose :type do |*|
        'Question'
      end

      expose :actor do |*|
        'https://example.com/actor/alice'
      end

      expose :content do |*|
        "What's up?"
      end
    end
  end

  let(:entity_class) { transitive_entity_class }

  shared_examples_for 'activity document' do
    it 'belongs to the ActivityStreams namespace' do
      expect(serializer['@context']).to eq 'https://www.w3.org/ns/activitystreams'
    end

    it 'has a unique identifier' do
      expect(serializer).to have_key 'id'
    end

    it 'has a type' do
      expect(serializer).to have_key 'type'
    end

    it 'has an actor' do
      expect(serializer['actor']).to eq 'https://example.com/actor/alice'
    end
  end

  before do
    implementer_class.entity entity_class
  end

  context 'with a valid represented entity' do
    it_behaves_like 'activity document'
  end

  context 'when the represented entity provides no identifier' do
    before do
      allow(entity_class).to receive(:represent).and_return({ type: 'Person', actor: 'http://something/' })
    end

    it 'raises an exception' do
      expect { serializer }.to raise_error(ActivityPub::ActivitySerializer::MissingIdentifierError)
    end
  end

  context 'when the represented entity provides no type' do
    before do
      allow(entity_class).to receive(:represent).and_return({
        id: 'http://something/',
        actor: 'http://something-else/'
      })
    end

    it 'raises an exception' do
      expect { serializer }.to raise_error(ActivityPub::ActivitySerializer::MissingTypeError)
    end
  end

  context 'when the represented entity provides no actor' do
    before do
      allow(entity_class).to receive(:represent).and_return({ id: 'http://something/', type: 'Person' })
    end

    it 'raises an exception' do
      expect { serializer }.to raise_error(ActivityPub::ActivitySerializer::MissingActorError)
    end
  end

  context 'when the represented entity provides no object' do
    let(:entity_class) { intransitive_entity_class }

    context 'when the caller provides the :intransitive option' do
      let(:serializer) { implementer_class.new.represent(resource, intransitive: true) }

      it_behaves_like 'activity document'
    end

    context 'when the caller does not provide the :intransitive option' do
      it 'raises an exception' do
        expect { serializer }.to raise_error(ActivityPub::ActivitySerializer::MissingObjectError)
      end
    end
  end

  context 'when the caller does provide the :intransitive option and an object' do
    let(:serializer) { implementer_class.new.represent(resource, intransitive: true) }

    it 'raises an exception' do
      expect { serializer }.to raise_error(ActivityPub::ActivitySerializer::IntransitiveWithObjectError)
    end
  end
end
