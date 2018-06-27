require 'rails_helper'

describe NoteDiffFile do
  describe 'associations' do
    it { is_expected.to belong_to(:diff_note) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:diff_note) }
  end
end
