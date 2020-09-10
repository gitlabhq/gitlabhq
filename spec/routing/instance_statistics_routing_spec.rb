# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Instance Statistics', 'routing' do
  include RSpec::Rails::RequestExampleGroup

  it "routes '/-/instance_statistics' to dev ops report" do
    expect(get('/-/instance_statistics')).to redirect_to('/admin/dev_ops_report')
  end
end
