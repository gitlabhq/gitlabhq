# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::CrossProjectReference do
  let(:including_class) { Class.new.include(described_class).new }

  before do
    allow(including_class).to receive(:context).and_return({})
    allow(including_class).to receive(:parent_from_ref).and_call_original
  end

  describe '#parent_from_ref' do
    context 'when no project was referenced' do
      it 'returns the project from context' do
        project = double

        allow(including_class).to receive(:context).and_return({ project: project })

        expect(including_class.parent_from_ref(nil)).to eq project
      end
    end

    context 'when no project was referenced in group context' do
      it 'returns the group from context' do
        group = double

        allow(including_class).to receive(:context).and_return({ group: group })

        expect(including_class.parent_from_ref(nil)).to eq group
      end
    end

    context 'when referenced project does not exist' do
      it 'returns nil' do
        expect(including_class.parent_from_ref('invalid/reference')).to be_nil
      end
    end

    context 'when referenced project exists' do
      it 'returns the referenced project' do
        project2 = double('referenced project')

        expect(Project).to receive(:find_by_full_path)
          .with('cross/reference').and_return(project2)

        expect(including_class.parent_from_ref('cross/reference')).to eq project2
      end
    end
  end
end
