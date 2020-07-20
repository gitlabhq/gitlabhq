# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::MergeRequestCounter do
  it_behaves_like 'a redis usage counter', 'Merge Request', :create

  it_behaves_like 'a redis usage counter with totals', :merge_request, create: 5
end
