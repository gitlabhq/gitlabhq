# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchNullifyDependentAssociations do
  before do
    test_user = Class.new(ActiveRecord::Base) do
      self.table_name = 'users'

      has_many :closed_issues, foreign_key: :closed_by_id, class_name: 'Issue', dependent: :nullify
      has_many :issues, foreign_key: :author_id, class_name: 'Issue', dependent: :nullify
      has_many :updated_issues, foreign_key: :updated_by_id, class_name: 'Issue'

      include BatchNullifyDependentAssociations
    end

    stub_const('TestUser', test_user)
  end

  describe '.dependent_associations_to_nullify' do
    it 'returns only associations with `dependent: :nullify` associations' do
      expect(TestUser.dependent_associations_to_nullify.map(&:name)).to match_array([:closed_issues, :issues])
    end
  end

  describe '#nullify_dependent_associations_in_batches' do
    let_it_be(:user) { create(:user) }
    let_it_be(:updated_by_issue) { create(:issue, updated_by: user) }

    before do
      create(:issue, closed_by: user)
      create(:issue, closed_by: user)
    end

    it 'nullifies multiple settings' do
      expect do
        test_user = TestUser.find(user.id)
        test_user.nullify_dependent_associations_in_batches
      end.to change { Issue.where(closed_by_id: user.id).count }.by(-2)
    end

    it 'excludes associations' do
      expect do
        test_user = TestUser.find(user.id)
        test_user.nullify_dependent_associations_in_batches(exclude: [:closed_issues])
      end.not_to change { Issue.where(closed_by_id: user.id).count }
    end
  end
end
