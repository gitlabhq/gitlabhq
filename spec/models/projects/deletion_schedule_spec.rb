# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DeletionSchedule, type: :model, feature_category: :groups_and_projects do
  subject(:project_deletion_schedule) { build(:project_deletion_schedule) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:marked_for_deletion_at) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }

    specify do
      expect(project_deletion_schedule).to belong_to(:deleting_user).class_name('User').with_foreign_key('user_id')
        .inverse_of(:project_deletion_schedules)
    end
  end
end
