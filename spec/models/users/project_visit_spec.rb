# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectVisit, feature_category: :navigation do
  let_it_be(:entity) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:base_time) { DateTime.now }

  before do
    described_class.create!(entity_id: entity.id, user_id: user.id, visited_at: base_time)
  end

  it_behaves_like 'namespace visits model'

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:project_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { entity }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:project_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { user }
  end
end
