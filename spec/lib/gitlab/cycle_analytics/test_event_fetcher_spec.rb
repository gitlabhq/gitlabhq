# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::TestEventFetcher do
  let(:stage_name) { :test }

  it_behaves_like 'default query config' do
    it 'has a default order' do
      expect(event.order).not_to be_nil
    end
  end
end
