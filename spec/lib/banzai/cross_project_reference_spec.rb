# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::CrossProjectReference, feature_category: :markdown do
  let(:including_class) { Class.new.include(described_class).new }
  let(:reference_cache) { Banzai::Filter::References::ReferenceCache.new(including_class, {}) }

  before do
    allow(including_class).to receive(:parent_from_ref).and_call_original
    allow(including_class).to receive_messages(context: {}, reference_cache: reference_cache)
  end

  describe '#parent_from_ref' do
    context 'when no project was referenced' do
      it 'returns the project from context' do
        project = build_stubbed(:project)

        allow(including_class).to receive(:context).and_return({ project: project })

        expect(including_class.parent_from_ref(nil)).to eq project
      end
    end

    context 'when no project was referenced in group context' do
      it 'returns the group from context' do
        group = build_stubbed(:group)

        allow(including_class).to receive(:context).and_return({ group: group })

        expect(including_class.parent_from_ref(nil)).to eq group
      end
    end

    context 'when no project was referenced in user context' do
      it 'returns nil' do
        user = build_stubbed(:user)

        allow(including_class).to receive(:context).and_return({ user: user })

        expect(including_class.parent_from_ref(nil)).to be_nil
      end
    end

    context 'when referenced project does not exist' do
      it 'returns nil' do
        expect(including_class.parent_from_ref('invalid/reference')).to be_nil
      end
    end

    context 'when referenced project exists' do
      it 'returns the referenced project' do
        referenced_project = build_stubbed(:project)

        expect(Project).to receive(:find_by_full_path)
          .with('cross/reference').and_return(referenced_project)

        expect(including_class.parent_from_ref('cross/reference')).to eq referenced_project
      end
    end

    context 'when reference cache is loaded' do
      let(:referenced_project) { build_stubbed(:project) }

      before do
        allow(reference_cache).to receive_messages(
          cache_loaded?: true,
          parent_per_reference: { 'cross/reference' => referenced_project }
        )
      end

      it 'pulls from the reference cache' do
        expect(including_class.parent_from_ref('cross/reference')).to eq referenced_project
      end
    end
  end
end
