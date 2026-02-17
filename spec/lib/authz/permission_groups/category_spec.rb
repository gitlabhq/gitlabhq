# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authz::PermissionGroups::Category, feature_category: :permissions do
  describe '.config_path' do
    it 'returns the glob pattern for category metadata files' do
      expect(described_class.config_path).to include('*/_metadata.yml')
    end
  end

  describe '.all' do
    it 'loads all categories with simple identifiers' do
      categories = described_class.all

      if categories.any?
        first_key = categories.each_key.first

        expect(first_key).to be_a(Symbol)
        expect(first_key.to_s).not_to include('/')
      end
    end
  end

  describe '.get' do
    context 'when category metadata exists' do
      let(:temp_dir) { Dir.mktmpdir }
      let(:base_path) { "#{temp_dir}/config/authz/permission_groups/assignable_permissions" }
      let(:category_metadata_file) { "#{base_path}/test_category/_metadata.yml" }
      let(:category_definition) { { 'name' => 'Test Category' } }

      before do
        FileUtils.mkdir_p(File.dirname(category_metadata_file))
        File.write(category_metadata_file, category_definition.to_yaml)

        stub_const("#{described_class}::BASE_PATH", "#{temp_dir}/config/authz/permission_groups/assignable_permissions")
        described_class.instance_variable_set(:@all, nil)
      end

      after do
        FileUtils.remove_entry(temp_dir)
        described_class.instance_variable_set(:@all, nil)
      end

      it 'retrieves a category by identifier' do
        category = described_class.get(:test_category)

        expect(category).to be_present
        expect(category.name).to eq('Test Category')
      end
    end

    it 'returns nil for non-existent category' do
      category = described_class.get(:nonexistent_category)

      expect(category).to be_nil
    end
  end

  describe 'instance methods' do
    let(:definition) { { name: 'CI/CD' } }
    let(:file_path) { "config/authz/permission_groups/assignable_permissions/ci_cd/_metadata.yml" }

    subject(:category) { described_class.new(definition, file_path) }

    describe '#name' do
      it 'returns the definition name' do
        expect(category.name).to eq(definition[:name])
      end
    end

    describe '#definition' do
      it 'returns the full definition' do
        expect(category.definition).to eq(definition)
      end
    end
  end
end
