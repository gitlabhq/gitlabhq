# frozen_string_literal: true

require 'spec_helper'

describe 'Instance Statistics', 'routing' do
  include RSpec::Rails::RequestExampleGroup

  it "routes '/-/instance_statistics' to dev ops score" do
    expect(get('/-/instance_statistics')).to redirect_to('/-/instance_statistics/dev_ops_score')
  end
end
