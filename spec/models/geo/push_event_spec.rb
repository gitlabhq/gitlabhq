require 'rails_helper'

RSpec.describe Geo::PushEvent, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe '#event_type' do
    it { is_expected.to define_enum_for(:event_type).with([:repository_updated, :wiki_updated]) }
  end
end
