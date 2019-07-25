# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::WikiPageCounter do
  it_behaves_like 'a redis usage counter', 'Wiki Page', :create
  it_behaves_like 'a redis usage counter', 'Wiki Page', :update
  it_behaves_like 'a redis usage counter', 'Wiki Page', :delete

  it_behaves_like 'a redis usage counter with totals', :wiki_pages,
    create: 5,
    update: 3,
    delete: 2
end
