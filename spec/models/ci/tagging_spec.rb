# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Tagging, feature_category: :continuous_integration do
  let_it_be(:tags) { create_pair(:ci_tag) }

  let_it_be(:other_taggings) do
    tags.map do |tag|
      described_class.create!(tag_id: tag.id, context: 'other')
    end
  end

  let_it_be(:default_taggings) do
    tags.map do |tag|
      described_class.create!(tag_id: tag.id, context: described_class::DEFAULT_CONTEXT)
    end
  end

  it { is_expected.to belong_to(:tag).class_name('Ci::Tag') }
  it { is_expected.to belong_to(:taggable) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:context) }
    it { is_expected.to validate_presence_of(:tag_id) }

    it 'validates uniqueness of tag_id' do
      is_expected.to validate_uniqueness_of(:tag_id)
        .scoped_to(%i[taggable_type taggable_id context tagger_id tagger_type])
    end
  end

  describe '.by_contexts' do
    it { expect(described_class.by_contexts(nil)).to match_array(default_taggings) }
    it { expect(described_class.by_contexts([described_class::DEFAULT_CONTEXT])).to match_array(default_taggings) }
    it { expect(described_class.by_contexts(['other'])).to match_array(other_taggings) }

    it 'works with multiple inputs' do
      expect(described_class.by_contexts([described_class::DEFAULT_CONTEXT, 'other']))
        .to match_array(default_taggings + other_taggings)
    end
  end

  describe '.by_context' do
    it { expect(described_class.by_context).to match_array(default_taggings) }
    it { expect(described_class.by_context(described_class::DEFAULT_CONTEXT)).to match_array(default_taggings) }
    it { expect(described_class.by_context('other')).to match_array(other_taggings) }
  end
end
