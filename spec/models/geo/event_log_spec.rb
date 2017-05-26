require 'rails_helper'

RSpec.describe Geo::EventLog, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:push_event).class_name('Geo::PushEvent').with_foreign_key('push_event_id') }
  end
end
