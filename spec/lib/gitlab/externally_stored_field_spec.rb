# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ExternallyStoredField, feature_category: :team_planning do
  before_all do
    ActiveRecord::Schema.define do
      create_table :_test_externally_stored_field_parents, force: true do |t|
        t.timestamps null: false
      end

      create_table :_test_externally_stored_fields, force: true do |t|
        t.references :parent, foreign_key: { to_table: :_test_externally_stored_field_parents }
        t.integer :file_store, limit: 2, null: false, default: 1
        t.integer :cached_markdown_version
        t.text :description
        t.text :description_html
        t.timestamps null: false
      end
    end
  end

  after(:all) do
    ActiveRecord::Schema.define do
      drop_table :_test_externally_stored_fields, force: true
      drop_table :_test_externally_stored_field_parents, force: true
    end
  end

  let(:uploader_class) do
    Class.new(GitlabUploader) do
      include ObjectStorage::Concern
      storage_location :agent_plan_content

      def store_dir
        '_test_externally_stored_fields'
      end

      def filename
        "#{model.id}.json"
      end
    end
  end

  let(:model_class) do
    uploader = uploader_class
    Class.new(ApplicationRecord) do
      self.table_name = '_test_externally_stored_fields'

      include Gitlab::ExternallyStoredField

      externally_stored_field :content
      self.external_storage_uploader_class = uploader

      def self.name
        'TestExternallyStoredModel'
      end
    end
  end

  let(:parent_class) do
    child_class = model_class
    Class.new(ApplicationRecord) do
      self.table_name = '_test_externally_stored_field_parents'

      has_one :child, anonymous_class: child_class, foreign_key: :parent_id, inverse_of: :parent, autosave: true

      def self.name
        'TestExternallyStoredParent'
      end
    end
  end

  before do
    p_class = parent_class
    model_class.reset_column_information
    model_class.belongs_to :parent, anonymous_class: p_class, foreign_key: :parent_id, inverse_of: :child,
      optional: true
  end

  describe 'virtual attribute accessors' do
    it 'defines reader, writer, and changed? methods' do
      instance = model_class.new

      expect(instance).to respond_to(:content)
      expect(instance).to respond_to(:content=)
      expect(instance).to respond_to(:content_changed?)
    end

    it 'tracks changes to virtual attributes' do
      instance = model_class.new

      expect(instance.content_changed?).to be false

      instance.content = 'new value'
      expect(instance.content_changed?).to be true
      expect(instance.content).to eq('new value')
    end
  end

  describe 'changed_attributes integration' do
    it 'includes virtual field changes in changed_attributes' do
      instance = model_class.new
      instance.content = 'test'

      attrs = instance.send(:changed_attributes)
      expect(attrs).to have_key('content')
    end

    it 'does not include unchanged virtual fields' do
      instance = model_class.new

      attrs = instance.send(:changed_attributes)
      expect(attrs).not_to have_key('content')
    end
  end

  describe 'lazy loading' do
    it 'does not load from storage until a field is accessed' do
      instance = model_class.create!
      instance.content = 'stored'
      instance.save!

      reloaded = model_class.find(instance.id)
      expect(reloaded.instance_variable_get(:@external_fields_loaded)).to be_nil

      reloaded.content
      expect(reloaded.instance_variable_get(:@external_fields_loaded)).to be true
    end
  end

  describe 'persistence' do
    it 'stores and retrieves field values via object storage' do
      instance = model_class.create!
      instance.content = 'round trip'
      instance.save!

      reloaded = model_class.find(instance.id)
      expect(reloaded.content).to eq('round trip')
    end

    it 'updates stored values on save' do
      instance = model_class.create!
      instance.content = 'original'
      instance.save!

      instance.content = 'modified'
      instance.save!

      reloaded = model_class.find(instance.id)
      expect(reloaded.content).to eq('modified')
    end

    it 'clears change tracking after persist' do
      instance = model_class.create!
      instance.content = 'test'
      instance.save!

      expect(instance.changes).to be_empty
    end
  end

  describe 'cleanup on destroy' do
    it 'removes the stored file' do
      instance = model_class.create!
      instance.content = 'doomed'
      instance.save!

      stored_path = instance.send(:external_storage_uploader).path
      expect(File.exist?(stored_path)).to be true

      instance.destroy!

      expect(File.exist?(stored_path)).to be false
    end
  end

  describe '#[]' do
    it 'returns the externally stored field value' do
      instance = model_class.create!
      instance.content = 'bracket access'
      instance.save!

      reloaded = model_class.find(instance.id)
      expect(reloaded[:content]).to eq('bracket access')
    end

    it 'falls through to super for AR attributes' do
      instance = model_class.create!

      expect(instance[:file_store]).to eq(1)
    end
  end

  describe 'setter tracks changes against stored value' do
    it 'detects change when setting nil on a field with a stored value without reading first' do
      instance = model_class.create!
      instance.content = 'previously stored'
      instance.save!

      reloaded = model_class.find(instance.id)
      reloaded.content = nil

      expect(reloaded.content_changed?).to be true
    end
  end

  describe '.externally_stored_fields' do
    it 'returns the set of registered fields' do
      expect(model_class.externally_stored_fields).to include(:content)
    end
  end

  describe 'autosave compatibility' do
    it 'persists externally stored field changes when saved via parent autosave' do
      parent = parent_class.create!
      child = model_class.create!(parent: parent, content: 'original')
      parent.reload

      parent.child.content = 'updated via autosave'
      parent.save!

      reloaded = model_class.find(child.id)
      expect(reloaded.content).to eq('updated via autosave')
    end
  end

  describe 'reload' do
    it 'clears cached externally stored field values so they are re-read from storage' do
      instance = model_class.create!
      instance.content = 'before reload'
      instance.save!

      expect(instance.content).to eq('before reload')

      other_ref = model_class.find(instance.id)
      other_ref.content = 'after external update'
      other_ref.save!

      instance.reload
      expect(instance.content).to eq('after external update')
    end
  end

  describe 'mixed AR and external storage with CacheMarkdownField' do
    let(:mixed_class) do
      uploader = uploader_class
      Class.new(ApplicationRecord) do
        self.table_name = '_test_externally_stored_fields'

        include CacheMarkdownField
        cache_markdown_field :description
        cache_markdown_field :content, storage: :external
        self.external_storage_uploader_class = uploader

        def self.name
          'TestMixedStorageModel'
        end
      end
    end

    let(:reverse_order_class) do
      uploader = uploader_class
      Class.new(ApplicationRecord) do
        self.table_name = '_test_externally_stored_fields'

        include CacheMarkdownField
        cache_markdown_field :content, storage: :external
        cache_markdown_field :description
        self.external_storage_uploader_class = uploader

        def self.name
          'TestReverseOrderMixedStorageModel'
        end
      end
    end

    before do
      stub_commonmark_sourcepos_disabled
    end

    it 'registers AR fields as non-external and external fields as external' do
      instance = mixed_class.new

      expect(instance.externally_stored_field?(:description)).to be false
      expect(instance.externally_stored_field?(:description_html)).to be false
      expect(instance.externally_stored_field?(:content)).to be true
      expect(instance.externally_stored_field?(:content_html)).to be true
    end

    it 'round-trips both field types through create and reload' do
      instance = mixed_class.new(description: '**bold description**')
      instance.content = '`code content`'
      instance.save!

      reloaded = mixed_class.find(instance.id)
      expect(reloaded.description).to eq('**bold description**')
      expect(reloaded.description_html).to include('<strong>')
      expect(reloaded.content).to eq('`code content`')
      expect(reloaded.content_html).to include('<code>')
    end

    it 'stores description_html in the DB column and content_html in the object store blob' do
      instance = mixed_class.new(description: '**db**')
      instance.content = '**blob**'
      instance.save!

      reloaded = mixed_class.find(instance.id)

      expect(reloaded.read_attribute(:description_html)).to include('<strong>')
      expect(mixed_class.column_names).not_to include('content_html')
      expect(reloaded.content_html).to include('<strong>')
    end

    it 'shares a single cached_markdown_version across both field types' do
      instance = mixed_class.new(description: 'a')
      instance.content = 'b'
      instance.save!

      reloaded = mixed_class.find(instance.id)
      expect(reloaded.cached_markdown_version).to eq(Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED)
    end

    it 'tracks changes independently per storage type' do
      instance = mixed_class.create!(description: 'original description')
      instance.content = 'original content'
      instance.save!

      reloaded = mixed_class.find(instance.id)

      reloaded.description = 'new description'
      expect(reloaded.markdown_field_changed?(:description)).to be true
      expect(reloaded.markdown_field_changed?(:content)).to be false

      reloaded2 = mixed_class.find(instance.id)

      reloaded2.content = 'new content'
      expect(reloaded2.markdown_field_changed?(:description)).to be false
      expect(reloaded2.markdown_field_changed?(:content)).to be true
    end

    it 'updates both field types independently' do
      instance = mixed_class.new(description: 'description v1')
      instance.content = 'content v1'
      instance.save!

      instance.description = 'description v2'
      instance.save!

      reloaded = mixed_class.find(instance.id)
      expect(reloaded.description).to eq('description v2')
      expect(reloaded.content).to eq('content v1')

      instance.content = 'content v2'
      instance.save!

      reloaded = mixed_class.find(instance.id)
      expect(reloaded.description).to eq('description v2')
      expect(reloaded.content).to eq('content v2')
    end

    it 'works regardless of declaration order' do
      instance = reverse_order_class.new(description: '**reversed**')
      instance.content = '`also reversed`'
      instance.save!

      reloaded = reverse_order_class.find(instance.id)
      expect(reloaded.description).to eq('**reversed**')
      expect(reloaded.description_html).to include('<strong>')
      expect(reloaded.content).to eq('`also reversed`')
      expect(reloaded.content_html).to include('<code>')

      expect(reloaded.externally_stored_field?(:description)).to be false
      expect(reloaded.externally_stored_field?(:content)).to be true
    end
  end
end
