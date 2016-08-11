require 'spec_helper'
require 'lib/gitlab/badge/shared/metadata'

describe Gitlab::Badge::Build::Metadata do
  let(:badge) { double(project: create(:project), ref: 'feature') }
  let(:metadata) { described_class.new(badge) }

  it_behaves_like 'badge metadata'

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include 'badges/feature/build.svg'
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include 'commits/feature'
    end
  end
end
