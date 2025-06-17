# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::DeletionSchedule, type: :model, feature_category: :groups_and_projects do
  subject(:namespace_deletion_schedule) { build(:namespace_deletion_schedule) }

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }

    specify do
      expect(namespace_deletion_schedule).to belong_to(:deleting_user)
        .class_name('User')
        .with_foreign_key('user_id')
        .inverse_of(:namespace_deletion_schedules)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:marked_for_deletion_at) }
  end
end
