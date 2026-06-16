# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountImportedProjectsTotalMetric,
  feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:gitea_imports) do
    create_list(:project, 3, import_type: 'gitea', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:bitbucket_imports) do
    create_list(:project, 2, import_type: 'bitbucket', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:gitlab_project_migration_import) do
    create(:project, import_type: 'gitlab_project_migration', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:fogbugz_import) do
    create(:project, import_type: 'fogbugz', creator_id: user.id, created_at: 3.weeks.ago)
  end

  let_it_be(:old_import) { create(:project, import_type: 'gitea', creator_id: user.id, created_at: 2.months.ago) }

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
  end

  context 'with all time frame' do
    let(:expected_value) { 8 }
    let(:expected_query) do
      "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" "\
      "IN ('gitlab_project', 'github', 'bitbucket', 'bitbucket_server', 'gitea', 'git', 'manifest', "\
      "'gitlab_project_migration', 'fogbugz')"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'for 28d time frame' do
    let(:expected_value) { 7 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" "\
      "IN ('gitlab_project', 'github', 'bitbucket', 'bitbucket_server', 'gitea', 'git', 'manifest', "\
      "'gitlab_project_migration', 'fogbugz') "\
      "AND \"projects\".\"created_at\" BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
  end
end
