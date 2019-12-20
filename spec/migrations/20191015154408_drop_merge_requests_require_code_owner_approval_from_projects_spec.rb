# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191015154408_drop_merge_requests_require_code_owner_approval_from_projects.rb')

describe DropMergeRequestsRequireCodeOwnerApprovalFromProjects, :migration do
  let(:projects_table) { table(:projects) }

  subject(:migration) { described_class.new }

  describe "without running the migration" do
    it "project_table has a :merge_requests_require_code_owner_approval column" do
      expect(projects_table.column_names)
        .to include("merge_requests_require_code_owner_approval")
    end

    it "project_table has a :projects_requiring_code_owner_approval index" do
      expect(ActiveRecord::Base.connection.indexes(:projects).collect(&:name))
        .to include("projects_requiring_code_owner_approval")
    end
  end

  describe '#up' do
    context "without running "
    before do
      migrate!
    end

    it "drops the :merge_requests_require_code_owner_approval column" do
      expect(projects_table.column_names)
        .not_to include("merge_requests_require_code_owner_approval")
    end

    it "drops the :projects_requiring_code_owner_approval index" do
      expect(ActiveRecord::Base.connection.indexes(:projects).collect(&:name))
        .not_to include("projects_requiring_code_owner_approval")
    end
  end

  describe "#down" do
    before do
      migration.up
      migration.down
    end

    it "project_table has a :merge_requests_require_code_owner_approval column" do
      expect(projects_table.column_names)
        .to include("merge_requests_require_code_owner_approval")
    end

    it "project_table has a :projects_requiring_code_owner_approval index" do
      expect(ActiveRecord::Base.connection.indexes(:projects).collect(&:name))
        .to include("projects_requiring_code_owner_approval")
    end
  end
end
