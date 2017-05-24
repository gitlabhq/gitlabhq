require 'rails_helper'

RSpec.describe GeoEventLog, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:push_event).class_name('GeoPushEvent').with_foreign_key('push_event_id') }
  end
end
