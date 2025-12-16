# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFilter, feature_category: :team_planning do
  describe '#allowed_types' do
    subject(:types_list) do
      described_class.new(container: container).allowed_types.sort
    end

    context 'when the container is a user namespace' do
      let_it_be(:container) { create(:user, :with_namespace).namespace }

      it 'returns empty list' do
        expect(types_list).to be_blank
      end
    end

    context 'when the container is a project' do
      let_it_be(:container) { create(:project) }

      it_behaves_like 'allowed work item types for a project'
    end

    context 'when the container is a group' do
      let_it_be(:container) { create(:group) }

      it_behaves_like 'allowed work item types for a group'
    end
  end
end
