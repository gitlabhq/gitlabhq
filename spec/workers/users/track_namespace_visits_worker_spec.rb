# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::TrackNamespaceVisitsWorker, feature_category: :navigation do
  describe '#perform' do
    let_it_be(:user) { create(:user) }

    context 'when tracking a group' do
      let_it_be(:entity) { create(:group) }
      let_it_be(:entity_type) { 'groups' }
      let_it_be(:worker) { described_class.new }
      let_it_be(:model) { ::Users::GroupVisit }

      it_behaves_like 'namespace visits tracking worker'
    end

    context 'when tracking a project' do
      let_it_be(:entity) { create(:project) }
      let_it_be(:entity_type) { 'projects' }
      let_it_be(:worker) { described_class.new }
      let_it_be(:model) { ::Users::ProjectVisit }

      it_behaves_like 'namespace visits tracking worker'
    end
  end
end
