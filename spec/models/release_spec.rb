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

  describe '.by_tag' do
    let(:tag) { release.tag }

    subject { described_class.by_tag(project, tag) }

    it { is_expected.to eq(release) }

    context 'when no releases exists' do
      let(:tag) { 'not-existing' }

      it { is_expected.to be_nil }
    end
  end
end
