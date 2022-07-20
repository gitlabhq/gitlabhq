# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActsAsTaggableOn::Tag' do
  describe '.find_or_create_all_with_like_by_name' do
    let(:tags) { %w[tag] }

    subject(:find_or_create) { ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tags) }

    it 'creates a tag' do
      expect { find_or_create }.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it 'returns the Tag record' do
      results = find_or_create

      expect(results.size).to eq(1)
      expect(results.first).to be_an_instance_of(ActsAsTaggableOn::Tag)
      expect(results.first.name).to eq('tag')
    end

    context 'some tags already existing' do
      let(:tags) { %w[tag preexisting_tag tag2] }

      before_all do
        ActsAsTaggableOn::Tag.create!(name: 'preexisting_tag')
      end

      it 'creates only the missing tag' do
        expect(ActsAsTaggableOn::Tag).to receive(:insert_all)
          .with([{ name: 'tag' }, { name: 'tag2' }], unique_by: :name)
          .and_call_original

        expect { find_or_create }.to change(ActsAsTaggableOn::Tag, :count).by(2)
      end

      it 'returns the Tag records' do
        results = find_or_create

        expect(results.map(&:name)).to match_array(tags)
      end
    end

    context 'all tags already existing' do
      let(:tags) { %w[preexisting_tag preexisting_tag2] }

      before_all do
        ActsAsTaggableOn::Tag.create!(name: 'preexisting_tag')
        ActsAsTaggableOn::Tag.create!(name: 'preexisting_tag2')
      end

      it 'does not create new tags' do
        expect { find_or_create }.not_to change(ActsAsTaggableOn::Tag, :count)
      end

      it 'returns the Tag records' do
        results = find_or_create

        expect(results.map(&:name)).to match_array(tags)
      end
    end
  end
end
