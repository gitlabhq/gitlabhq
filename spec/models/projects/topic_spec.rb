# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Topic do
  let_it_be(:topic, reload: true) { create(:topic, name: 'topic') }

  subject { topic }

  it { expect(subject).to be_valid }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Avatarable) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:project_topics) }
    it { is_expected.to have_many(:projects) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  describe 'scopes' do
    describe 'order_by_total_projects_count' do
      let!(:topic1) { create(:topic, name: 'topicB') }
      let!(:topic2) { create(:topic, name: 'topicC') }
      let!(:topic3) { create(:topic, name: 'topicA') }
      let!(:project1) { create(:project, topic_list: 'topicC, topicA, topicB') }
      let!(:project2) { create(:project, topic_list: 'topicC, topicA') }
      let!(:project3) { create(:project, topic_list: 'topicC') }

      it 'sorts topics by total_projects_count' do
        topics = described_class.order_by_total_projects_count

        expect(topics.map(&:name)).to eq(%w[topicC topicA topicB topic])
      end
    end

    describe 'reorder_by_similarity' do
      let!(:topic1) { create(:topic, name: 'my-topic') }
      let!(:topic2) { create(:topic, name: 'other') }
      let!(:topic3) { create(:topic, name: 'topic2') }

      it 'sorts topics by similarity' do
        topics = described_class.reorder_by_similarity('topic')

        expect(topics.map(&:name)).to eq(%w[topic my-topic topic2 other])
      end
    end
  end

  describe '#search' do
    it 'returns topics with a matching name' do
      expect(described_class.search(topic.name)).to eq([topic])
    end

    it 'returns topics with a partially matching name' do
      expect(described_class.search(topic.name[0..2])).to eq([topic])
    end

    it 'returns topics with a matching name regardless of the casing' do
      expect(described_class.search(topic.name.upcase)).to eq([topic])
    end
  end

  describe '#avatar_type' do
    it "is true if avatar is image" do
      topic.update_attribute(:avatar, 'uploads/avatar.png')
      expect(topic.avatar_type).to be_truthy
    end

    it "is false if avatar is html page" do
      topic.update_attribute(:avatar, 'uploads/avatar.html')
      topic.avatar_type

      expect(topic.errors.added?(:avatar, "file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff, ico, webp")).to be true
    end
  end

  describe '#avatar_url' do
    context 'when avatar file is uploaded' do
      before do
        topic.update!(avatar: fixture_file_upload("spec/fixtures/dk.png"))
      end

      it 'shows correct avatar url' do
        expect(topic.avatar_url).to eq(topic.avatar.url)
        expect(topic.avatar_url(only_path: false)).to eq([Gitlab.config.gitlab.url, topic.avatar.url].join)
      end
    end
  end
end
