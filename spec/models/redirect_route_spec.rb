require 'rails_helper'

describe RedirectRoute, models: true do
  let!(:group) { create(:group, path: 'git_lab', name: 'git_lab') }
  let!(:redirect_route) { group.redirect_routes.create(path: 'gitlabb') }

  describe 'relationships' do
    it { is_expected.to belong_to(:source) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path) }
  end
end
