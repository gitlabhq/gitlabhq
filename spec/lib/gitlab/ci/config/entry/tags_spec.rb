# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Tags do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when tags config value is correct' do
      let(:config) { %w[tag1 tag2] }

      describe '#value' do
        it 'returns tags configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      describe '#errors' do
        context 'when tags config is not an array of strings' do
          let(:config) { [1, 2] }

          it 'reports error' do
            expect(entry.errors)
              .to include 'tags config should be an array of strings'
          end
        end

        context 'when tags limit is reached' do
          let(:config) { Array.new(50) { |i| "tag-#{i}" } }

          it 'reports error' do
            expect(entry.errors)
              .to include "tags config must be less than the limit of #{described_class::TAGS_LIMIT} tags"
          end
        end
      end
    end
  end
end
