# frozen_string_literal: true

require 'spec_helper'
require 'lib/gitlab/ci/badge/shared/metadata'

RSpec.describe Gitlab::Ci::Badge::Custom::Metadata, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }
  let(:badge) { Gitlab::Ci::Badge::Custom::CustomBadge.new(project, opts: {}) }
  let(:metadata) { described_class.new(badge) }

  it_behaves_like 'badge metadata'

  describe '#title' do
    it 'returns badge title' do
      expect(metadata.title).to eq 'custom'
    end
  end

  describe '#image_url' do
    it 'returns valid url' do
      expect(metadata.image_url).to include '/-/badges/custom.svg'
    end
  end

  describe '#link_url' do
    it 'returns valid link' do
      expect(metadata.link_url).to include project.full_path
    end
  end
end
