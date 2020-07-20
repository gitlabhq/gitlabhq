# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::IssueEventFetcher do
  let(:stage_name) { :issue }

  it_behaves_like 'default query config'
end
