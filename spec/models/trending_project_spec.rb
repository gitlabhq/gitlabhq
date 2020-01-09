# frozen_string_literal: true

require 'spec_helper'

describe TrendingProject do
  let(:user) { create(:user) }
  let(:public_project1) { create(:project, :public) }
  let(:public_project2) { create(:project, :public) }
  let(:public_project3) { create(:project, :public) }
  let(:private_project) { create(:project, :private) }
  let(:internal_project) { create(:project, :internal) }

  before do
    create_list(:note_on_commit, 3, project: public_project1)

    create_list(:note_on_commit, 2, project: public_project2)

    create(:note_on_commit, project: public_project3, created_at: 5.weeks.ago)
    create(:note_on_commit, project: private_project)
    create(:note_on_commit, project: internal_project)
  end

  describe '.refresh!' do
    before do
      described_class.refresh!
    end

    it 'populates the trending projects table' do
      expect(described_class.count).to eq(2)
    end

    it 'removes existing rows before populating the table' do
      described_class.refresh!

      expect(described_class.count).to eq(2)
    end

    it 'stores the project IDs for every trending project' do
      rows = described_class.order(id: :asc).all

      expect(rows[0].project_id).to eq(public_project1.id)
      expect(rows[1].project_id).to eq(public_project2.id)
    end

    it 'does not store projects that fall out of the trending time range' do
      expect(described_class.where(project_id: public_project3).any?).to eq(false)
    end

    it 'stores only public projects' do
      expect(described_class.where(project_id: [public_project1.id, public_project2.id]).count).to eq(2)
      expect(described_class.where(project_id: [private_project.id, internal_project.id]).count).to eq(0)
    end
  end
end
