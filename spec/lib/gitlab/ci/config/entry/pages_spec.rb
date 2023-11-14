# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Pages, feature_category: :pages do
  subject(:entry) { described_class.new(config) }

  describe 'validation' do
    context 'when value given is not a hash' do
      let(:config) { 'value' }

      it 'is invalid' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include('pages config should be a hash')
      end
    end

    context 'when value is a hash' do
      context 'when the hash is valid' do
        let(:config) { { path_prefix: 'prefix' } }

        it 'is valid' do
          expect(entry).to be_valid
          expect(entry.value).to eq({
            path_prefix: 'prefix'
          })
        end
      end

      context 'when path_prefix key is not a string' do
        let(:config) { { path_prefix: 1 } }

        it 'is invalid' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include('pages path prefix should be a string')
        end
      end

      context 'when hash contains not allowed keys' do
        let(:config) { { unknown: 'echo' } }

        it 'is invalid' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include('pages config contains unknown keys: unknown')
        end
      end
    end
  end
end
