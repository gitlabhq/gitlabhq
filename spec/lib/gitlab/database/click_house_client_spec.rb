# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClickHouse::Client', feature_category: :database do
  context 'when click_house spec tag is not added' do
    it 'does not have any ClickHouse databases configured' do
      databases = ClickHouse::Client.configuration.databases

      expect(databases).to be_empty
    end
  end

  describe 'when click_house spec tag is added', :click_house do
    around do |example|
      with_net_connect_allowed do
        example.run
      end
    end

    it 'has a ClickHouse database configured' do
      databases = ClickHouse::Client.configuration.databases

      expect(databases).not_to be_empty
    end

    it 'returns data from the DB' do
      result = ClickHouse::Client.execute("SELECT 1 AS value", :main)

      expect(result).to eq([{ 'value' => 1 }])
    end
  end
end
