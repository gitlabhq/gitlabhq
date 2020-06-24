# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::DesignsCounter do
  it_behaves_like 'a redis usage counter', 'Designs', :create
  it_behaves_like 'a redis usage counter', 'Designs', :update
  it_behaves_like 'a redis usage counter', 'Designs', :delete

  it_behaves_like 'a redis usage counter with totals', :design_management_designs,
    create: 5,
    update: 3,
    delete: 2
end
