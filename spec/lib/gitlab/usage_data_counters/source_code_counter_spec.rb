# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::SourceCodeCounter do
  it_behaves_like 'a redis usage counter', 'Source Code', :pushes

  it_behaves_like 'a redis usage counter with totals', :source_code, pushes: 5
end
