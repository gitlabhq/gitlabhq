# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountImportedProjectsTotalMetric do
  let_it_be(:user) { create(:user) }
  let_it_be(:gitea_imports) do
    create_list(:project, 3, import_type: 'gitea', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:bitbucket_imports) do
    create_list(:project, 2, import_type: 'bitbucket', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:old_import) { create(:project, import_type: 'gitea', creator_id: user.id, created_at: 2.months.ago) }

  let_it_be(:bulk_import_projects) do
    create_list(:bulk_import_entity, 3, :project_entity, created_at: 3.weeks.ago)
  end

  let_it_be(:bulk_import_groups) do
    create_list(:bulk_import_entity, 3, :group_entity, created_at: 3.weeks.ago)
  end

  let_it_be(:old_bulk_import_project) do
    create(:bulk_import_entity, :project_entity, created_at: 2.months.ago)
  end

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
  end

  context 'with all time frame' do
    let(:expected_value) { 10 }
    let(:expected_query) do
      "SELECT (SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" "\
      "IN ('gitlab_project', 'gitlab', 'github', 'bitbucket', 'bitbucket_server', 'gitea', 'git', 'manifest', "\
      "'gitlab_migration')) "\
      "+ (SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\" "\
      "WHERE \"bulk_import_entities\".\"source_type\" = 1)"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'for 28d time frame' do
    let(:expected_value) { 8 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT (SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" "\
      "IN ('gitlab_project', 'gitlab', 'github', 'bitbucket', 'bitbucket_server', 'gitea', 'git', 'manifest', "\
      "'gitlab_migration') "\
      "AND \"projects\".\"created_at\" BETWEEN '#{start}' AND '#{finish}') "\
      "+ (SELECT COUNT(\"bulk_import_entities\".\"id\") FROM \"bulk_import_entities\" "\
      "WHERE \"bulk_import_entities\".\"source_type\" = 1 AND \"bulk_import_entities\".\"created_at\" "\
      "BETWEEN '#{start}' AND '#{finish}')"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
  end
end
