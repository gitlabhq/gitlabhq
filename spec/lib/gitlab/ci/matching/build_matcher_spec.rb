# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Matching::BuildMatcher do
  let(:dummy_attributes) do
    {
      protected: true,
      tag_list: %w[tag1 tag2],
      build_ids: [1, 2, 3],
      project: :my_project
    }
  end

  subject(:matcher) { described_class.new(attributes) }

  describe '.new' do
    context 'when attributes are missing' do
      let(:attributes) { {} }

      it { expect { matcher }.to raise_error(KeyError) }
    end

    context 'with attributes' do
      let(:attributes) { dummy_attributes }

      it { expect(matcher.protected).to eq(true) }

      it { expect(matcher.tag_list).to eq(%w[tag1 tag2]) }

      it { expect(matcher.build_ids).to eq([1, 2, 3]) }

      it { expect(matcher.project).to eq(:my_project) }
    end
  end

  describe '#protected?' do
    context 'when protected is set to true' do
      let(:attributes) { dummy_attributes }

      it { expect(matcher.protected?).to be_truthy }
    end

    context 'when protected is set to false' do
      let(:attributes) { dummy_attributes.merge(protected: false) }

      it { expect(matcher.protected?).to be_falsey }
    end
  end

  describe '#has_tags?' do
    context 'when tags are present' do
      let(:attributes) { dummy_attributes }

      it { expect(matcher.has_tags?).to be_truthy }
    end

    context 'when tags are empty' do
      let(:attributes) { dummy_attributes.merge(tag_list: []) }

      it { expect(matcher.has_tags?).to be_falsey }
    end
  end
end
