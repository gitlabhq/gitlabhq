# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::SnippetCounter do
  it_behaves_like 'a redis usage counter', 'Snippet', :create
  it_behaves_like 'a redis usage counter', 'Snippet', :update

  it_behaves_like 'a redis usage counter with totals', :snippet,
    create: 3,
    update: 2
end
