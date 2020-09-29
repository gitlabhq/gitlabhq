# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::Global do
  let(:global) { described_class.new(hash) }
  let(:default_static_site_generator_value) { 'middleman' }

  shared_examples_for 'valid default configuration' do
    describe '#compose!' do
      before do
        global.compose!
      end

      it 'creates nodes hash' do
        expect(global.descendants).to be_an Array
      end

      it 'creates node object for each entry' do
        expect(global.descendants.count).to eq 1
      end

      it 'creates node object using valid class' do
        expect(global.descendants.first)
          .to be_an_instance_of expected_node_object_class
      end

      it 'sets correct description for nodes' do
        expect(global.descendants.first.description)
          .to eq 'Configuration of the Static Site Editor static site generator.'
      end

      describe '#leaf?' do
        it 'is not leaf' do
          expect(global).not_to be_leaf
        end
      end
    end

    context 'when not composed' do
      describe '#static_site_generator_value' do
        it 'returns nil' do
          expect(global.static_site_generator_value).to be nil
        end
      end

      describe '#leaf?' do
        it 'is leaf' do
          expect(global).to be_leaf
        end
      end
    end

    context 'when composed' do
      before do
        global.compose!
      end

      describe '#errors' do
        it 'has no errors' do
          expect(global.errors).to be_empty
        end
      end

      describe '#static_site_generator_value' do
        it 'returns correct values' do
          expect(global.static_site_generator_value).to eq(default_static_site_generator_value)
        end
      end
    end
  end

  describe '.nodes' do
    it 'returns a hash' do
      expect(described_class.nodes).to be_a(Hash)
    end

    context 'when filtering all the entry/node names' do
      it 'contains the expected node names' do
        expect(described_class.nodes.keys)
          .to match_array(%i[static_site_generator])
      end
    end
  end

  context 'when configuration is valid' do
    context 'when some entries defined' do
      let(:expected_node_object_class) { Gitlab::StaticSiteEditor::Config::FileConfig::Entry::StaticSiteGenerator }
      let(:hash) do
        { static_site_generator: default_static_site_generator_value }
      end

      it_behaves_like 'valid default configuration'
    end
  end

  context 'when value is an empty hash' do
    let(:expected_node_object_class) { Gitlab::Config::Entry::Unspecified }
    let(:hash) { {} }

    it_behaves_like 'valid default configuration'
  end

  context 'when configuration is not valid' do
    before do
      global.compose!
    end

    context 'when static_site_generator is invalid' do
      let(:hash) do
        { static_site_generator: { not_a_string: true } }
      end

      describe '#errors' do
        it 'reports errors' do
          expect(global.errors)
            .to include 'static_site_generator config should be a string'
        end
      end
    end

    context 'when there is an invalid key' do
      let(:hash) do
        { invalid_key: true }
      end

      describe '#errors' do
        it 'reports errors' do
          expect(global.errors)
            .to include 'global config contains unknown keys: invalid_key'
        end
      end
    end
  end

  context 'when value is not a hash' do
    let(:hash) { [] }

    describe '#valid?' do
      it 'is not valid' do
        expect(global).not_to be_valid
      end
    end

    describe '#errors' do
      it 'returns error about invalid type' do
        expect(global.errors.first).to match /should be a hash/
      end
    end
  end

  describe '#specified?' do
    it 'is concrete entry that is defined' do
      expect(global.specified?).to be true
    end
  end

  describe '#[]' do
    before do
      global.compose!
    end

    let(:hash) do
      { static_site_generator: default_static_site_generator_value }
    end

    context 'when entry exists' do
      it 'returns correct entry' do
        expect(global[:static_site_generator])
          .to be_an_instance_of Gitlab::StaticSiteEditor::Config::FileConfig::Entry::StaticSiteGenerator
        expect(global[:static_site_generator].value).to eq default_static_site_generator_value
      end
    end

    context 'when entry does not exist' do
      it 'always return unspecified node' do
        expect(global[:some][:unknown][:node])
          .not_to be_specified
      end
    end
  end
end
