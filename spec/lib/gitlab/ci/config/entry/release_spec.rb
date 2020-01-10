# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Release do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) { { tag_name: 'v0.06', description: "./release_changelog.txt" } }

      describe '#value' do
        it 'returns release configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context "when value includes 'assets' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          assets: [
            {
              name: "cool-app.zip",
              url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
            }
          ]
        }
      end

      describe '#value' do
        it 'returns release configuration' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context "when value includes 'name' keyword" do
      let(:config) do
        {
          tag_name: 'v0.06',
          description: "./release_changelog.txt",
          name: "Release $CI_TAG_NAME"
        }
      end

      describe '#value' do
        it 'returns release configuration' do
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
        context 'when value of attribute is invalid' do
          let(:config) { { description: 10 } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'release description should be a string'
          end
        end

        context 'when release description is missing' do
          let(:config) { { tag_name: 'v0.06' } }

          it 'reports error' do
            expect(entry.errors)
              .to include "release description can't be blank"
          end
        end

        context 'when release tag_name is missing' do
          let(:config) { { description: "./release_changelog.txt" } }

          it 'reports error' do
            expect(entry.errors)
              .to include "release tag name can't be blank"
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { test: 100 } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'release config contains unknown keys: test'
          end
        end
      end
    end
  end
end
