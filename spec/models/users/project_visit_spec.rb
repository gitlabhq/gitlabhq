# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::ProjectVisit, feature_category: :navigation do
  let_it_be(:entity) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:base_time) { DateTime.now }

  it_behaves_like 'namespace visits model'

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:project_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { entity }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:project_visit, entity_id: entity.id, user_id: user.id, visited_at: base_time) }
    let!(:parent) { user }
  end

  describe '#frecent_projects' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }

    before do
      [
        [project1.id, 1.day.ago],
        [project2.id, 2.days.ago]
      ].each do |id, datetime|
        described_class.create!(entity_id: id, user_id: user.id, visited_at: datetime)
      end
    end

    it "returns the associated frecently visited projects" do
      expect(described_class.frecent_projects(user_id: user.id)).to eq([
        project1,
        project2
      ])
    end
  end
end
