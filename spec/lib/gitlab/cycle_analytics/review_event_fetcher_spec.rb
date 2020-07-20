# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::ReviewEventFetcher do
  let(:stage_name) { :review }

  it_behaves_like 'default query config'
end
