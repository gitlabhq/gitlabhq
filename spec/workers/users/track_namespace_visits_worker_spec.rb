# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::TrackNamespaceVisitsWorker, feature_category: :navigation do
  describe '#perform' do
    let_it_be(:user, freeze: false) { create(:user) }

    context 'when tracking a group' do
      let_it_be(:entity, freeze: false) { create(:group) }
      let_it_be(:entity_type, freeze: false) { 'groups' }
      let_it_be(:worker, freeze: false) { described_class.new }
      let_it_be(:model, freeze: false) { ::Users::GroupVisit }

      it_behaves_like 'namespace visits tracking worker'
    end

    context 'when tracking a project' do
      let_it_be(:entity, freeze: false) { create(:project) }
      let_it_be(:entity_type, freeze: false) { 'projects' }
      let_it_be(:worker, freeze: false) { described_class.new }
      let_it_be(:model, freeze: false) { ::Users::ProjectVisit }

      it_behaves_like 'namespace visits tracking worker'
    end
  end
end
