# frozen_string_literal: true
# rubocop:disable RSpec/FactoriesInMigrationSpecs
require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180723130817_delete_inconsistent_internal_id_records.rb')

describe DeleteInconsistentInternalIdRecords, :migration do
  let!(:project1) { create(:project) }
  let!(:project2) { create(:project) }
  let!(:project3) { create(:project) }

  let(:internal_id_query) { ->(project) { InternalId.where(usage: InternalId.usages[scope.to_s.tableize], project: project) } }

  let(:create_models) do
    3.times { create(scope, project: project1) }
    3.times { create(scope, project: project2) }
    3.times { create(scope, project: project3) }
  end

  shared_examples_for 'deleting inconsistent internal_id records' do
    before do
      create_models

      internal_id_query.call(project1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(project3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent issues" do
      expect { migrate! }.to change { internal_id_query.call(project1).size }.from(1).to(0)
    end

    it "retains consistent issues" do
      expect { migrate! }.not_to change { internal_id_query.call(project2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(project3).size }
    end
  end

  context 'for issues' do
    let(:scope) { :issue }
    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for merge_requests' do
    let(:scope) { :merge_request }

    let(:create_models) do
      3.times { |i| create(scope, target_project: project1, source_project: project1, source_branch: i.to_s) }
      3.times { |i| create(scope, target_project: project2, source_project: project2, source_branch: i.to_s) }
      3.times { |i| create(scope, target_project: project3, source_project: project3, source_branch: i.to_s) }
    end

    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for deployments' do
    let(:scope) { :deployment }
    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for milestones (by project)' do
    let(:scope) { :milestone }
    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for ci_pipelines' do
    let(:scope) { :ci_pipeline }
    it_behaves_like 'deleting inconsistent internal_id records'
  end

  context 'for milestones (by group)' do
    # milestones (by group) is a little different than most of the other models
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group3) { create(:group) }

    let(:internal_id_query) { ->(group) { InternalId.where(usage: InternalId.usages['milestones'], namespace: group) } }

    before do
      3.times { create(:milestone, group: group1) }
      3.times { create(:milestone, group: group2) }
      3.times { create(:milestone, group: group3) }

      internal_id_query.call(group1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(group3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent issues" do
      expect { migrate! }.to change { internal_id_query.call(group1).size }.from(1).to(0)
    end

    it "retains consistent issues" do
      expect { migrate! }.not_to change { internal_id_query.call(group2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(group3).size }
    end
  end

  context 'for milestones (by group)' do
    # epics (by group) is a little different than most of the other models
    let!(:group1) { create(:group) }
    let!(:group2) { create(:group) }
    let!(:group3) { create(:group) }
    let!(:user)   { create(:user) }

    let(:internal_id_query) { ->(group) { InternalId.where(usage: InternalId.usages['epics'], namespace: group) } }

    before do
      # we use state enum in Epic but state field was added after this migration
      epics = table(:epics)

      epics.belongs_to(:group)
      epics.include(AtomicInternalId)
      epics.has_internal_id(:iid, scope: :group, init: ->(s) { s&.group&.epics&.maximum(:iid) })

      epics.create!(title: 'Epic 1', title_html: 'Epic 1', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 2', title_html: 'Epic 2', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 3', title_html: 'Epic 3', group_id: group1.id, author_id: user.id)
      epics.create!(title: 'Epic 4', title_html: 'Epic 4', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 5', title_html: 'Epic 5', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 6', title_html: 'Epic 6', group_id: group2.id, author_id: user.id)
      epics.create!(title: 'Epic 7', title_html: 'Epic 7', group_id: group3.id, author_id: user.id)
      epics.create!(title: 'Epic 8', title_html: 'Epic 8', group_id: group3.id, author_id: user.id)
      epics.create!(title: 'Epic 9', title_html: 'Epic 9', group_id: group3.id, author_id: user.id)

      internal_id_query.call(group1).first.tap do |iid|
        iid.last_value = iid.last_value - 2
        # This is an inconsistent record
        iid.save!
      end

      internal_id_query.call(group3).first.tap do |iid|
        iid.last_value = iid.last_value + 2
        # This is a consistent record
        iid.save!
      end
    end

    it "deletes inconsistent records" do
      expect { migrate! }.to change { internal_id_query.call(group1).size }.from(1).to(0)
    end

    it "retains consistent records" do
      expect { migrate! }.not_to change { internal_id_query.call(group2).size }
    end

    it "retains consistent records, especially those with a greater last_value" do
      expect { migrate! }.not_to change { internal_id_query.call(group3).size }
    end
  end
end
