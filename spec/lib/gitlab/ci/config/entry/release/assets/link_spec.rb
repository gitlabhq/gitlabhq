# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Release::Assets::Link do
  let(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when entry config value is correct' do
      let(:config) do
        {
          name: "cool-app.zip",
          url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip"
        }
      end

      describe '#value' do
        it 'returns link configuration' do
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
        context 'when name is not a string' do
          let(:config) { { name: 123, url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip" } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'link name should be a string'
          end
        end

        context 'when name is not present' do
          let(:config) { { url: "http://my.awesome.download.site/1.0-$CI_COMMIT_SHORT_SHA.zip" } }

          it 'reports error' do
            expect(entry.errors)
              .to include "link name can't be blank"
          end
        end

        context 'when url is not addressable' do
          let(:config) { { name: "cool-app.zip", url: "xyz" } }

          it 'reports error' do
            expect(entry.errors)
              .to include "link url is blocked: only allowed schemes are http, https"
          end
        end

        context 'when url is not present' do
          let(:config) { { name: "cool-app.zip" } }

          it 'reports error' do
            expect(entry.errors)
              .to include "link url can't be blank"
          end
        end

        context 'when there is an unknown key present' do
          let(:config) { { test: 100 } }

          it 'reports error' do
            expect(entry.errors)
              .to include 'link config contains unknown keys: test'
          end
        end
      end
    end
  end
end
