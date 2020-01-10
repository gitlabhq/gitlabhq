# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Release::Assets do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) do
        {
          links: [
            {
              name: "cool-app.zip",
              url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
            },
            {
              name: "cool-app.exe",
              url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.exe"
            }
          ]
        }
      end

      describe '#value' do
        it 'returns assets configuration' do
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
        context 'when value of assets is invalid' do
          let(:config) { { links: 'xyz' } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'assets links should be an array of hashes'
          end
        end

        context 'when value of assets:links is empty' do
          let(:config) { { links: [] } }

          it 'reports error' do
            expect(entry.errors)
              .to include "assets links can't be blank"
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { test: 100 } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'assets config contains unknown keys: test'
          end
        end
      end
    end
  end
end
