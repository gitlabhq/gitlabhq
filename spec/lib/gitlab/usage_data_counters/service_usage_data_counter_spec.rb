# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::ServiceUsageDataCounter do
  it_behaves_like 'a redis usage counter', 'Service Usage Data', :download_payload_click
end
