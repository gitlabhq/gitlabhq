# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateExistingSubgroupToMatchVisibilityLevelOfParent, schema: 2020_01_10_121314 do
  include MigrationHelpers::NamespacesHelpers

  context 'private visibility level' do
    it 'updates the project visibility' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      expect { subject.perform([parent.id], Gitlab::VisibilityLevel::PRIVATE) }.to change { child.reload.visibility_level }.to(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates sub-sub groups' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::PRIVATE, parent_id: parent.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      subject.perform([parent.id, middle_group.id], Gitlab::VisibilityLevel::PRIVATE)

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end

    it 'updates all sub groups' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE)
      middle_group = create_namespace('middle', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: middle_group.id)

      subject.perform([parent.id], Gitlab::VisibilityLevel::PRIVATE)

      expect(child.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      expect(middle_group.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
    end
  end

  context 'internal visibility level' do
    it 'updates the project visibility' do
      parent = create_namespace('parent', Gitlab::VisibilityLevel::INTERNAL)
      child = create_namespace('child', Gitlab::VisibilityLevel::PUBLIC, parent_id: parent.id)

      expect { subject.perform([parent.id], Gitlab::VisibilityLevel::INTERNAL) }.to change { child.reload.visibility_level }.to(Gitlab::VisibilityLevel::INTERNAL)
    end
  end
end
