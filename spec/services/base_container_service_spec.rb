# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BaseContainerService, feature_category: :container_registry do
  let_it_be(:group) { build_stubbed(:group) }
  let_it_be(:subgroup) { build_stubbed(:group, parent: group) }
  let_it_be(:project) { build_stubbed(:project, group: group) }
  let_it_be(:user) { User.new }

  let(:container) { project }

  subject(:instance) { described_class.new(container: container, current_user: user) }

  describe '#initialize' do
    it 'accepts container and current_user' do
      expect(instance.container).to eq(project)
      expect(instance.current_user).to eq(user)
    end

    it 'treats current_user as optional' do
      instance = described_class.new(container: project)

      expect(instance.current_user).to be_nil
    end
  end

  describe '.root_ancestor' do
    context 'when container is a group' do
      let(:container) { subgroup }

      it 'returns the top level group' do
        expect(instance.root_ancestor).to eq(group)
      end
    end

    context 'when container is a project' do
      it 'returns the project top level group' do
        expect(instance.root_ancestor).to eq(group)
      end

      context 'when the project does not belong to a group' do
        let(:container) { build_stubbed(:project) }

        it 'returns nil' do
          expect(instance.root_ancestor).to be_nil
        end
      end
    end
  end
end
