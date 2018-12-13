require 'rails_helper'

RSpec.describe Release do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:release) { create(:release, project: project, author: user) }

  it { expect(release).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author).class_name('User') }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:description) }
  end
end
