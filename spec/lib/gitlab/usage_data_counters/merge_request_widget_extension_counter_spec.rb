# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::MergeRequestWidgetExtensionCounter do
  it_behaves_like 'a redis usage counter', 'Widget Extension', :test_summary_count_expand

  it_behaves_like 'a redis usage counter with totals', :i_code_review_merge_request_widget, test_summary_count_expand: 5
end
