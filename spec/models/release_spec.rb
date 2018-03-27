require 'rails_helper'

RSpec.describe Release do
  let(:release) { create(:release) }

  it { expect(release).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:description) }
  end
end
