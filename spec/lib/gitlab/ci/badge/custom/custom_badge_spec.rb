# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Badge::Custom::CustomBadge, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :repository) }

  let(:badge) { described_class.new(project) }

  describe '#entity' do
    it 'always says custom' do
      expect(badge.entity).to eq 'custom'
    end
  end

  describe '#template' do
    it 'returns badge key_text' do
      expect(badge.template.key_text).to eq 'custom'
    end

    it 'returns badge value_text' do
      expect(badge.template.value_text).to eq 'none'
    end
  end

  describe '#metadata' do
    it 'returns badge metadata' do
      expect(badge.metadata.image_url).to include 'badges/custom.svg'
    end
  end
end
