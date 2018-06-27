require 'rails_helper'

describe ProjectImportState, type: :model do
  subject { create(:import_state) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
