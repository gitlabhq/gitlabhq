require 'spec_helper'

RSpec.describe Geo::EventLogState, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:event_id) }
  end
end
