require 'spec_helper'
require 'lib/gitlab/badge/shared/metadata'

describe Gitlab::Badge::Pipeline::Metadata do
  let(:badge) { double(project: create(:project), ref: 'feature') }
  let(:metadata) { described_class.new(badge) }

  it_behaves_like 'badge metadata'

  describe '#title' do
    it 'returns build status title' do
      expect(metadata.title).to eq 'pipeline status'
    end
  end

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include 'badges/feature/pipeline.svg'
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include 'commits/feature'
    end
  end
end
