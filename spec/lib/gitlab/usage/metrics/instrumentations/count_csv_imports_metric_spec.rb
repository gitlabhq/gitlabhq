# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountCsvImportsMetric, feature_category: :service_ping do
  let_it_be(:user) { create(:user) }

  let_it_be(:old_import) { create(:issue_csv_import, user: user, created_at: 2.months.ago) }
  let_it_be(:new_import) { create(:issue_csv_import, user: user, created_at: 21.days.ago) }

  context 'with all time frame' do
    let(:expected_value) { 2 }
    let(:expected_query) do
      %q{SELECT COUNT("csv_issue_imports"."id") FROM "csv_issue_imports"}
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: 'all'
  end

  context 'for 28d time frame' do
    let(:expected_value) { 1 }
    let(:start) { 30.days.ago.to_fs(:db) }
    let(:finish) { 2.days.ago.to_fs(:db) }
    let(:expected_query) do
      "SELECT COUNT(\"csv_issue_imports\".\"id\") FROM \"csv_issue_imports\" " \
        "WHERE \"csv_issue_imports\".\"created_at\" " \
        "BETWEEN '#{start}' AND '#{finish}'"
    end

    it_behaves_like 'a correct instrumented metric value and query', time_frame: '28d'
  end
end
