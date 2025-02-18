# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Tag, feature_category: :continuous_integration do
  let_it_be(:tags) do
    [create(:ci_tag, name: 'Awesome'), create(:ci_tag, name: 'awesome'), create(:ci_tag, name: 'epic')]
  end

  it { is_expected.to have_many(:job_taggings).class_name('Ci::BuildTag') }
  it { is_expected.to have_many(:runner_taggings).class_name('Ci::RunnerTagging') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).ignoring_case_sensitivity }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe '.named' do
    it { expect(described_class.named('Awesome')).to contain_exactly(tags.first) }
  end

  describe '.named_like' do
    it { expect(described_class.named_like('awes')).to contain_exactly(*tags[0..1]) }
  end

  describe '.named_any' do
    it { expect(described_class.named_any(%w[awesome epic])).to contain_exactly(*tags[1..]) }
  end

  describe '.find_or_create_all_with_like_by_name' do
    let(:tags) { %w[tag] }

    subject(:find_or_create) { described_class.find_or_create_all_with_like_by_name(tags) }

    it 'creates a tag' do
      expect { find_or_create }.to change { described_class.count }.by(1)
    end

    it 'returns the Tag record' do
      results = find_or_create

      expect(results.size).to eq(1)
      expect(results.first).to be_an_instance_of(described_class)
      expect(results.first.name).to eq('tag')
    end

    context 'with some tags already existing' do
      let(:tags) { %w[tag preexisting_tag tag2] }

      let_it_be(:preexisting_tag) do
        create(:ci_tag, name: 'preexisting_tag')
      end

      it 'creates only the missing tag' do
        expect(described_class).to receive(:insert_all)
          .with([{ name: 'tag' }, { name: 'tag2' }], unique_by: :name)
          .and_call_original

        expect { find_or_create }.to change { described_class.count }.by(2)
      end

      it 'returns the Tag records' do
        results = find_or_create

        expect(results.map(&:name)).to match_array(tags)
      end
    end

    context 'with all tags already existing' do
      let(:tags) { %w[preexisting_tag preexisting_tag2] }

      before_all do
        create(:ci_tag, name: 'preexisting_tag')
        create(:ci_tag, name: 'preexisting_tag2')
      end

      it 'does not create new tags' do
        expect { find_or_create }.not_to change { described_class.count }
      end

      it 'returns the Tag records' do
        results = find_or_create

        expect(results.map(&:name)).to match_array(tags)
      end
    end
  end

  describe '.find_or_create_with_like_by_name' do
    let(:tag_name) { 'tag' }

    subject(:find_or_create) { described_class.find_or_create_with_like_by_name(tag_name) }

    it 'creates a tag' do
      expect { find_or_create }.to change { described_class.count }.by(1)
    end

    it 'returns the Tag record' do
      result = find_or_create

      expect(result).to be_an_instance_of(described_class)
      expect(result.name).to eq(tag_name)
    end

    context 'when tag already exists' do
      let_it_be(:tag) { create(:ci_tag, name: 'tag') }

      it 'does not create new tag' do
        expect { find_or_create }.not_to change { described_class.count }
      end

      it 'returns the Tag record' do
        result = find_or_create

        expect(result.name).to eq(tag_name)
      end
    end
  end

  describe '#==' do
    let(:tag) { tags.first }

    let(:subclass) { Class.new(described_class) }

    it 'is equal to itself' do
      expect(tag).to eq(tag)
    end

    it 'is equal to another tag when the name matches' do
      expect(tag).to eq(described_class.new(name: tag.name))
    end

    it 'is equal the other when the class matches' do
      expect(tag).to eq(subclass.new(name: tag.name))
    end
  end

  describe '#to_s' do
    it { expect(tags.first.to_s).to eq(tags.first.name) }
  end
end
