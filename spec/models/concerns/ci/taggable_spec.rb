# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Taggable, feature_category: :continuous_integration do
  let_it_be(:taggings_model) do
    Class.new(Ci::ApplicationRecord) do |_model|
      connection.create_table :_test_gitlab_ci_taggings, force: true do |t|
        t.integer :tag_id
        t.integer :test_ci_taggable_id

        t.index [:tag_id, :test_ci_taggable_id], unique: true, name: '_test_taggable_idx'
      end

      self.table_name = '_test_gitlab_ci_taggings'

      def self.name
        'TestCiTaggings'
      end

      include BulkInsertSafe

      belongs_to :tag, class_name: 'Ci::Tag', optional: false
    end
  end

  let_it_be(:taggable_model) do
    Class.new(Ci::ApplicationRecord) do |_model|
      connection.create_table :_test_gitlab_ci_taggable, force: true do |t|
        t.string :name
      end

      self.table_name = '_test_gitlab_ci_taggable'

      def self.name
        'TestCiTaggable'
      end

      include Ci::Taggable
    end
  end

  let_it_be(:configuration_class) do
    Class.new do
      attr_accessor :join_model, :unique_by

      def attributes_map(record)
        { test_ci_taggable_id: record.id }
      end
    end
  end

  let_it_be(:configuration) do
    configuration_class.new.tap do |c|
      c.join_model = taggings_model
      c.unique_by = [:tag_id, :test_ci_taggable_id]
    end
  end

  let(:taggable_record) { taggable_model.new(name: 'tags') }

  before do
    taggable_model.has_many :taggings, anonymous_class: taggings_model
    taggable_model.has_many :tags, class_name: 'Ci::Tag', through: :taggings, source: :tag

    taggings_model.scope :scoped_taggables, -> {
      where('_test_gitlab_ci_taggings.test_ci_taggable_id = _test_gitlab_ci_taggable.id')
    }

    allow(taggable_model).to receive(:taggings_join_model) { taggings_model }

    config = instance_double(Gitlab::Ci::Tags::BulkInsert::ConfigurationFactory, build: configuration)

    allow(Gitlab::Ci::Tags::BulkInsert::ConfigurationFactory).to receive(:new)
      .with(an_instance_of(taggable_model)).and_return(config)
  end

  it { expect(taggable_record).to have_many(:taggings) }
  it { expect(taggable_record).to have_many(:tags).class_name('Ci::Tag').through(:taggings) }

  it { expect(taggable_record.tag_list).to be_empty }
  it { expect(taggable_record.tag_list).to be_a(Gitlab::Ci::Tags::TagList) }

  it 'sets the tag list' do
    taggable_record.tag_list = 'ruby, docker, postgres'

    expect(taggable_record.tag_list).to match_array(%w[ruby docker postgres])
    expect(taggable_record.tag_list).to be_a(Gitlab::Ci::Tags::TagList)
  end

  it 'persists the tag list' do
    taggable_record.tag_list = 'ruby, docker, postgres'

    expect { taggable_record.save! }.to change { Ci::Tag.count }.by(3)
  end

  it 'loads the tag list' do
    taggable_record.tag_list = 'ruby, docker, postgres'
    taggable_record.save!
    fresh_record = taggable_model.find(taggable_record.id)

    expect(fresh_record.tag_list).to match_array(%w[ruby docker postgres])
    expect(fresh_record.tags).to be_all(Ci::Tag)
  end

  it 'removes unwanted tags from the list' do
    taggable_record.tag_list = 'ruby, docker, postgres'
    taggable_record.save!

    taggable_record.tag_list = 'ruby, docker'
    expect { taggable_record.save! }
      .to change { taggings_model.count }.by(-1)

    expect(taggable_record.reload.tag_list).to match_array(%w[ruby docker])
  end

  it 'updates the tag list' do
    taggable_record.tag_list = 'ruby, docker, postgres'
    taggable_record.save!

    taggable_record.tag_list = 'ruby, docker, elasticsearch, golang'

    expect { taggable_record.save! }
      .to change { Ci::Tag.count }.by(2)
      .and change { taggings_model.count }.by(1)

    expect(taggable_record.reload.tag_list).to match_array(%w[ruby docker elasticsearch golang])
  end

  describe '.tagged_with' do
    let!(:tags) { taggable_model.create!(name: 'tags', tag_list: 'ruby, docker, postgres') }
    let!(:other_tags) { taggable_model.create!(name: 'other tags', tag_list: 'ruby, golang') }

    it { expect(taggable_model.tagged_with('ruby')).to match_array([tags, other_tags]) }
    it { expect(taggable_model.tagged_with('ruby, docker')).to match_array([tags]) }
    it { expect(taggable_model.tagged_with(%w[ruby docker])).to match_array([tags]) }
    it { expect(taggable_model.tagged_with(%w[ruby docker golang])).to be_empty }
    it { expect(taggable_model.tagged_with('uby', like_search_enabled: false)).to be_empty }
    it { expect(taggable_model.tagged_with('uby', like_search_enabled: true)).to match_array([tags, other_tags]) }
    it { expect(taggable_model.tagged_with('uby')).to be_empty }
  end

  describe '#reload' do
    before do
      taggable_record.tag_list = 'ruby, docker, postgres'
      taggable_record.save!
    end

    it { expect { taggable_record.reload }.to change { taggable_record.tag_list.object_id } }
  end
end
