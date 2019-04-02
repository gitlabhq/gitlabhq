# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Release do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :public, :repository) }
  let(:release) { create(:release, project: project, author: user) }

  it { expect(release).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to have_many(:links).class_name('Releases::Link') }
  end

  describe 'validation' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:description) }
  end

  describe '#assets_count' do
    subject { release.assets_count }

    it 'returns the number of sources' do
      is_expected.to eq(Releases::Source::FORMATS.count)
    end

    context 'when a links exists' do
      let!(:link) { create(:release_link, release: release) }

      it 'counts the link as an asset' do
        is_expected.to eq(1 + Releases::Source::FORMATS.count)
      end
    end
  end

  describe '#sources' do
    subject { release.sources }

    it 'returns sources' do
      is_expected.to all(be_a(Releases::Source))
    end
  end
end
