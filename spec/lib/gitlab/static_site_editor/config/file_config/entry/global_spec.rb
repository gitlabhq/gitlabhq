# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::FileConfig::Entry::Global do
  let(:global) { described_class.new(hash) }
  let(:default_image_upload_path_value) { 'source/images' }

  let(:default_mounts_value) do
    [
      {
        source: 'source',
        target: ''
      }
    ]
  end

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
        expect(global.descendants.count).to eq 3
      end

      it 'creates node object using valid class' do
        expect(global.descendants.map(&:class)).to match_array(expected_node_object_classes)
      end

      it 'sets a description containing "Static Site Editor" for all nodes' do
        expect(global.descendants.map(&:description)).to all(match(/Static Site Editor/))
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

      describe '#image_upload_path_value' do
        it 'returns correct values' do
          expect(global.image_upload_path_value).to eq(default_image_upload_path_value)
        end
      end

      describe '#mounts_value' do
        it 'returns correct values' do
          expect(global.mounts_value).to eq(default_mounts_value)
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
        expected_node_names = %i[
          image_upload_path
          mounts
          static_site_generator
        ]
        expect(described_class.nodes.keys).to match_array(expected_node_names)
      end
    end
  end

  context 'when configuration is valid' do
    context 'when some entries defined' do
      let(:expected_node_object_classes) do
        [
          Gitlab::StaticSiteEditor::Config::FileConfig::Entry::ImageUploadPath,
          Gitlab::StaticSiteEditor::Config::FileConfig::Entry::Mounts,
          Gitlab::StaticSiteEditor::Config::FileConfig::Entry::StaticSiteGenerator
        ]
      end

      let(:hash) do
        {
          image_upload_path: default_image_upload_path_value,
          mounts: default_mounts_value,
          static_site_generator: default_static_site_generator_value
        }
      end

      it_behaves_like 'valid default configuration'
    end
  end

  context 'when value is an empty hash' do
    let(:expected_node_object_classes) do
      [
        Gitlab::Config::Entry::Unspecified,
        Gitlab::Config::Entry::Unspecified,
        Gitlab::Config::Entry::Unspecified
      ]
    end

    let(:hash) { {} }

    it_behaves_like 'valid default configuration'
  end

  context 'when configuration is not valid' do
    before do
      global.compose!
    end

    context 'when a single entry is invalid' do
      let(:hash) do
        { image_upload_path: { not_a_string: true } }
      end

      describe '#errors' do
        it 'reports errors' do
          expect(global.errors)
            .to include 'image_upload_path config should be a string'
        end
      end
    end

    context 'when a multiple entries are invalid' do
      let(:hash) do
        {
          image_upload_path: { not_a_string: true },
          static_site_generator: { not_a_string: true }
        }
      end

      describe '#errors' do
        it 'reports errors' do
          expect(global.errors)
            .to match_array([
                              'image_upload_path config should be a string',
                              'static_site_generator config should be a string',
                              "static_site_generator config should be 'middleman'"
                            ])
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
