require 'spec_helper'

RSpec.describe Geo::EventLog, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:repository_updated_event).class_name('Geo::RepositoryUpdatedEvent').with_foreign_key('repository_updated_event_id') }
    it { is_expected.to belong_to(:repository_renamed_event).class_name('Geo::RepositoryRenamedEvent').with_foreign_key('repository_renamed_event_id') }
  end
end
