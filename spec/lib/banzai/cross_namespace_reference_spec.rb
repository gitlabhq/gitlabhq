# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::CrossNamespaceReference, feature_category: :markdown do
  let(:including_class) { Class.new.include(described_class).new }
  let(:reference_cache) { Banzai::Filter::References::ReferenceCache.new(including_class, {}, {}) }

  before do
    allow(including_class).to receive(:parent_from_ref).and_call_original
    allow(including_class).to receive_messages(context: {}, reference_cache: reference_cache)
  end

  describe '#parent_from_ref' do
    context 'when no project was referenced' do
      it 'returns the project from context' do
        project = instance_double(Project)

        allow(including_class).to receive(:context).and_return({ project: project })

        expect(including_class.parent_from_ref(nil)).to eq project
      end
    end

    context 'when no project was referenced in group context' do
      it 'returns the group from context' do
        group = instance_double(Namespace)

        allow(including_class).to receive(:context).and_return({ group: group })

        expect(including_class.parent_from_ref(nil)).to eq group
      end
    end

    context 'when referenced namespace does not exist' do
      it 'returns nil' do
        expect(including_class.parent_from_ref('invalid/reference')).to be_nil
      end
    end

    context 'when referenced namespace exists' do
      it 'returns the referenced namespace' do
        namespace2 = instance_double(Namespace)

        expect(Namespace).to receive(:find_by_full_path)
          .with('cross/reference').and_return(namespace2)

        expect(including_class.parent_from_ref('cross/reference')).to eq namespace2
      end
    end

    context 'when reference cache is loaded' do
      let(:namespace2) { instance_double(Namespace) }

      before do
        allow(reference_cache).to receive_messages(cache_loaded?: true,
          parent_per_reference: { 'cross/reference' => namespace2 })
      end

      it 'pulls from the reference cache' do
        expect(including_class.parent_from_ref('cross/reference')).to eq namespace2
      end
    end
  end
end
