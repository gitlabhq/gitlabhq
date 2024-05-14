# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Imageable do
  let(:node_class) do
    Class.new(::Gitlab::Config::Entry::Node) do
      include ::Gitlab::Ci::Config::Entry::Imageable

      validations do
        validates :config, allowed_keys: ::Gitlab::Ci::Config::Entry::Imageable::IMAGEABLE_ALLOWED_KEYS
      end

      def self.name
        'node'
      end

      def value
        if string?
          { name: @config }
        elsif hash?
          {
            name: @config[:name]
          }.compact
        else
          {}
        end
      end
    end
  end

  subject(:entry) { node_class.new(config) }

  before do
    entry.compose!
  end

  context 'when entry value is correct' do
    let(:config) { 'image:1.0' }

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when entry value is not correct' do
    let(:config) { ['image:1.0'] }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors.first)
          .to match(/config should be a hash or a string/)
      end
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end
  end

  context 'when unexpected key is specified' do
    let(:config) { { name: 'image:1.0', non_existing: 'test' } }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors.first)
          .to match(/config contains unknown keys: non_existing/)
      end
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end
  end
end
