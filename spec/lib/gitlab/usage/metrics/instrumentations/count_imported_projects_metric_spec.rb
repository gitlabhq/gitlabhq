# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountImportedProjectsMetric do
  let_it_be(:user) { create(:user) }

  # Project records have to be created chronologically, because of
  # metric SQL query optimizations that rely on the fact that `id`s
  # increment monotonically over time.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89701
  let_it_be(:old_import) { create(:project, import_type: 'gitea', creator_id: user.id, created_at: 2.months.ago) }
  let_it_be(:gitea_import_1) { create(:project, import_type: 'gitea', creator_id: user.id, created_at: 21.days.ago) }

  let_it_be(:gitea_import_2) do
    create(:project, import_type: 'gitea', creator_id: user.id, created_at: 20.days.ago)
  end

  let_it_be(:gitea_import_3) do
    create(:project, import_type: 'gitea', creator_id: user.id, created_at: 19.days.ago)
  end

  let_it_be(:bitbucket_import_1) do
    create(:project, import_type: 'bitbucket', creator_id: user.id, created_at: 2.weeks.ago)
  end

  let_it_be(:bitbucket_import_2) do
    create(:project, import_type: 'bitbucket', creator_id: user.id, created_at: 1.week.ago)
  end

  context 'with import_type gitea' do
    context 'with all time frame' do
      let(:expected_value) { 4 }
      let(:expected_query) do
        "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" = 'gitea'"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { import_type: 'gitea' }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 3 }
      let(:start) { 30.days.ago.to_fs(:db) }
      let(:finish) { 2.days.ago.to_fs(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"created_at\" "\
        "BETWEEN '#{start}' AND '#{finish}' AND \"projects\".\"import_type\" = 'gitea'"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { import_type: 'gitea' }
    end
  end

  context 'with import_type bitbucket' do
    context 'with all time frame' do
      let(:expected_value) { 2 }
      let(:expected_query) do
        "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"import_type\" = 'bitbucket'"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: 'all',
        options: { import_type: 'bitbucket' }
    end

    context 'for 28d time frame' do
      let(:expected_value) { 2 }
      let(:start) { 30.days.ago.to_fs(:db) }
      let(:finish) { 2.days.ago.to_fs(:db) }
      let(:expected_query) do
        "SELECT COUNT(\"projects\".\"id\") FROM \"projects\" WHERE \"projects\".\"created_at\" "\
        "BETWEEN '#{start}' AND '#{finish}' AND \"projects\".\"import_type\" = 'bitbucket'"
      end

      it_behaves_like 'a correct instrumented metric value and query',
        time_frame: '28d',
        options: { import_type: 'bitbucket' }
    end
  end
end
