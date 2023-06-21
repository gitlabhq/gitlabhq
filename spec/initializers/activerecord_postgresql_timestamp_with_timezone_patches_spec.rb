# frozen_string_literal: true

require 'spec_helper'

# A missing test to provide full coverage for the patch
RSpec.describe 'ActiveRecord PostgreSQL Timespamp With Timezone', feature_category: :database do
  before do
    load Rails.root.join('config/initializers/activerecord_postgresql_timestamp_with_timezone_patches.rb')
  end

  describe '#cast_value' do
    it 'returns local time' do
      timestamp = ActiveRecord::ConnectionAdapters::PostgreSQL::OID::TimestampWithTimeZone.new

      allow(ActiveRecord).to receive(:default_timezone).and_return(:local)

      expect(timestamp.cast_value(DateTime.now)).not_to be_utc
    end
  end
end
