# frozen_string_literal: true

require 'spec_helper'
require 'lib/gitlab/ci/badge/shared/metadata'

RSpec.describe Gitlab::Ci::Badge::Coverage::Metadata do
  let(:badge) do
    double(project: create(:project), ref: 'feature', job: 'test')
  end

  let(:metadata) { described_class.new(badge) }

  it_behaves_like 'badge metadata'

  describe '#title' do
    it 'returns coverage report title' do
      expect(metadata.title).to eq 'coverage report'
    end
  end

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include 'badges/feature/coverage.svg'
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include 'commits/feature'
    end
  end
end
