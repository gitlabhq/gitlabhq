# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse::Client', feature_category: :database do
  it 'does not have any databases configured' do
    databases = ClickHouse::Client.configuration.databases

    expect(databases).to be_empty
  end
end
