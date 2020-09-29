# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::StaticSiteGenerator do
  let(:static_site_generator) { described_class.new(config) }

  describe 'validations' do
    context 'when value is valid' do
      let(:config) { 'middleman' }

      describe '#value' do
        it 'returns a static_site_generator key' do
          expect(static_site_generator.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(static_site_generator).to be_valid
        end
      end
    end

    context 'when value is invalid' do
      let(:config) { 'not-a-valid-generator' }

      describe '#valid?' do
        it 'is not valid' do
          expect(static_site_generator).not_to be_valid
        end
      end
    end

    context 'when value has a wrong type' do
      let(:config) { { not_a_string: true } }

      it 'reports errors about wrong type' do
        expect(static_site_generator.errors)
          .to include 'static site generator config should be a string'
      end
    end
  end

  describe '.default' do
    it 'returns default static_site_generator' do
      expect(described_class.default).to eq 'middleman'
    end
  end
end
