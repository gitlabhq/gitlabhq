# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20191004081520_fill_productivity_analytics_start_date.rb')

describe FillProductivityAnalyticsStartDate, :migration do
  let(:settings_table) { table('application_settings') }
  let(:metrics_table) { table('merge_request_metrics') }

  before do
    settings_table.create!
  end

  context 'with NO productivity analytics data available' do
    it 'sets start_date to NOW' do
      expect { migrate! }.to change {
        settings_table.first&.productivity_analytics_start_date
      }.to(be_like_time(Time.now))
    end
  end

  context 'with productivity analytics data available' do
    before do
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute('ALTER TABLE merge_request_metrics DISABLE TRIGGER ALL')
        metrics_table.create!(merged_at: Time.parse('2019-09-09'), commits_count: nil, merge_request_id: 3)
        metrics_table.create!(merged_at: Time.parse('2019-10-10'), commits_count: 5, merge_request_id: 1)
        metrics_table.create!(merged_at: Time.parse('2019-11-11'), commits_count: 10, merge_request_id: 2)
        ActiveRecord::Base.connection.execute('ALTER TABLE merge_request_metrics ENABLE TRIGGER ALL')
      end
    end

    it 'set start_date to earliest merged_at value with PA data available' do
      expect { migrate! }.to change {
        settings_table.first&.productivity_analytics_start_date
      }.to(be_like_time(Time.parse('2019-10-10')))
    end
  end
end
