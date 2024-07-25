# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Taggable, feature_category: :continuous_integration do
  let_it_be(:taggable_model) do
    Class.new(Ci::ApplicationRecord) do |_model|
      connection.create_table :_test_gitlab_ci_taggings, force: true do |t|
        t.string :name
      end

      self.table_name = '_test_gitlab_ci_taggings'

      def self.name
        'TestCiTaggings'
      end

      include Ci::Taggable
    end
  end

  let(:taggable_record) { taggable_model.new(name: 'tags') }

  it { expect(taggable_record).to have_many(:taggings).class_name('Ci::Tagging') }
  it { expect(taggable_record).to have_many(:tag_taggings).class_name('Ci::Tagging') }
  it { expect(taggable_record).to have_many(:tags).class_name('Ci::Tag').through(:tag_taggings) }
  it { expect(taggable_record).to have_many(:base_tags).class_name('Ci::Tag').through(:taggings) }

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
    expect { taggable_record.save! }.to change { Ci::Tagging.count }.by(-1)
    expect(taggable_record.reload.tag_list).to match_array(%w[ruby docker])
  end

  it 'updates the tag list' do
    taggable_record.tag_list = 'ruby, docker, postgres'
    taggable_record.save!

    taggable_record.tag_list = 'ruby, docker, elasticsearch, golang'

    expect { taggable_record.save! }
      .to change { Ci::Tag.count }.by(2)
      .and change { Ci::Tagging.count }.by(1)

    expect(taggable_record.reload.tag_list).to match_array(%w[ruby docker elasticsearch golang])
  end

  describe '.tagged_with' do
    let_it_be(:tags) { taggable_model.create!(name: 'tags', tag_list: 'ruby, docker, postgres') }
    let_it_be(:other_tags) { taggable_model.create!(name: 'other tags', tag_list: 'ruby, golang') }

    it { expect(taggable_model.tagged_with('ruby')).to match_array([tags, other_tags]) }
    it { expect(taggable_model.tagged_with('ruby, docker')).to match_array([tags]) }
    it { expect(taggable_model.tagged_with(%w[ruby docker])).to match_array([tags]) }
    it { expect(taggable_model.tagged_with(%w[ruby docker golang])).to be_empty }
  end

  describe '#reload' do
    before do
      taggable_record.tag_list = 'ruby, docker, postgres'
      taggable_record.save!
    end

    it { expect { taggable_record.reload }.to change { taggable_record.tag_list.object_id } }
  end

  describe '#dirtify_tag_list' do
    before do
      taggable_record.tag_list = 'ruby, docker, postgres'
      taggable_record.save!
    end

    it 'resets the tag list after a tag is added' do
      expect { taggable_record.tags << create(:ci_tag) }
        .to change { Ci::Tagging.count }.by(1)
        .and change { taggable_record.tag_list.size }.by(1)
        .and change { taggable_record.tag_list_changed? }.to(true)
    end

    it 'resets the tag list after a tag is removed' do
      expect { taggable_record.tags.destroy(Ci::Tag.find_by_name('docker')) }
        .to change { Ci::Tagging.count }.by(-1)
        .and change { taggable_record.tag_list.size }.by(-1)
        .and change { taggable_record.tag_list_changed? }.to(true)
    end
  end
end
