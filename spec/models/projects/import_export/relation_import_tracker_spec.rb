# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ImportExport::RelationImportTracker, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:relation) }

    describe '#cannot_be_created_for_importing_project' do
      let_it_be(:project) do
        create(:project, import_state: create(:import_state))
      end

      context 'when the project is currently importing' do
        it 'can not be created' do
          project.import_state.schedule

          tracker = described_class.new(project: project)
          expect(tracker.valid?).to be false
          expect(tracker.errors[:base]).to include(
            _('Relation import tracker cannot be created for project with ongoing import')
          )
        end
      end

      context 'when the project is not currently importing' do
        it 'can be created' do
          project.import_state.cancel

          tracker = described_class.create!(project: project, relation: 'issues')
          expect(tracker.valid?).to be true
        end
      end
    end
  end

  describe '#stale?' do
    context 'when older than 24 hours' do
      let_it_be(:status) { build(:relation_import_tracker, created_at: 2.days.ago) }

      it 'is stale if created' do
        status.status = 0
        expect(status.stale?).to be true
      end

      it 'is stale if started' do
        status.status = 1
        expect(status.stale?).to be true
      end

      it 'is not stale if finished' do
        status.status = 2
        expect(status.stale?).to be false
      end

      it 'is not stale if failed' do
        status.status = 3
        expect(status.stale?).to be false
      end
    end

    context 'when younger than 24 hours' do
      let_it_be(:status) { build(:relation_import_tracker, created_at: (23.hours + 59.minutes).ago) }

      it 'is not stale' do
        expect(status.stale?).to be false
      end
    end
  end
end
