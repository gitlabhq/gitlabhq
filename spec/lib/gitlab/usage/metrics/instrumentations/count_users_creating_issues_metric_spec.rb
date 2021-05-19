# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersCreatingIssuesMetric do
  let_it_be(:author) { create(:user) }
  let_it_be(:issues) { create_list(:issue, 2, author: author, created_at: 4.days.ago) }
  let_it_be(:old_issue) { create(:issue, author: author, created_at: 2.months.ago) }

  context 'with all time frame' do
    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', data_source: 'database' }, 1
  end

  context 'for 28d time frame' do
    it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' }, 1
  end
end
