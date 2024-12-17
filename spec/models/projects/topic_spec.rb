# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Topic do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:topic, reload: true) { create(:topic, name: 'topic', organization: organization) }

  subject { topic }

  it { expect(subject).to be_valid }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Avatarable) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:project_topics) }
    it { is_expected.to have_many(:projects) }
    it { is_expected.to belong_to(:organization) }
  end

  describe 'validations' do
    let(:name_format_message) { 'has characters that are not allowed' }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:organization_id).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { expect(described_class.new).to validate_presence_of(:title) }
    it { expect(described_class.new).to validate_length_of(:title).is_at_most(255) }
    it { is_expected.not_to allow_value("new\nline").for(:name).with_message(name_format_message) }
    it { is_expected.not_to allow_value("new\rline").for(:name).with_message(name_format_message) }
    it { is_expected.not_to allow_value("new\vline").for(:name).with_message(name_format_message) }
    it { is_expected.not_to allow_value('トピック').for(:name).with_message('must only include ASCII characters') }

    context 'for slug' do
      let(:slug_format_message) { "can contain only letters, digits, '_', '-', '.'" }

      it { is_expected.to validate_length_of(:slug).is_at_most(255) }
      it { is_expected.to validate_uniqueness_of(:slug).scoped_to(:organization_id).case_insensitive }

      it { is_expected.not_to allow_value("new\nline").for(:slug).with_message(slug_format_message) }
      it { is_expected.not_to allow_value("space value").for(:slug).with_message(slug_format_message) }
      it { is_expected.not_to allow_value("$special_symbol_value").for(:slug).with_message(slug_format_message) }

      it { is_expected.to allow_value("underscored_value").for(:slug) }
      it { is_expected.to allow_value("hypened-value").for(:slug) }
      it { is_expected.to allow_value("dotted.value").for(:slug) }
    end
  end

  describe 'scopes' do
    describe 'without_assigned_projects' do
      let_it_be(:unassigned_topic) { create(:topic, name: 'unassigned topic', organization: organization) }
      let_it_be(:project) { create(:project, :public, topic_list: 'topic', organization: organization) }

      it 'returns topics without assigned projects' do
        topics = described_class.without_assigned_projects

        expect(topics).to contain_exactly(unassigned_topic)
      end
    end

    describe 'order_by_non_private_projects_count' do
      let_it_be(:topic1) { create(:topic, name: 'topicB', organization: organization) }
      let_it_be(:topic2) { create(:topic, name: 'topicC', organization: organization) }
      let_it_be(:topic3) { create(:topic, name: 'topicA', organization: organization) }
      let_it_be(:project2) { create(:project, :public, topic_list: 'topicC, topicA', organization: organization) }
      let_it_be(:project3) { create(:project, :public, topic_list: 'topicC', organization: organization) }

      let_it_be(:project1) do
        create(:project, :public, topic_list: 'topicC, topicA, topicB', organization: organization)
      end

      it 'sorts topics by non_private_projects_count' do
        topics = described_class.order_by_non_private_projects_count

        expect(topics.map(&:name)).to eq(%w[topicC topicA topicB topic])
      end
    end

    describe 'reorder_by_similarity' do
      let_it_be(:topic1) { create(:topic, name: 'my-topic') }
      let_it_be(:topic2) { create(:topic, name: 'other') }
      let_it_be(:topic3) { create(:topic, name: 'topic2') }

      it 'sorts topics by similarity' do
        topics = described_class.reorder_by_similarity('topic')

        expect(topics.map(&:name)).to eq(%w[topic my-topic topic2 other])
      end
    end
  end

  describe '#find_by_name_case_insensitive' do
    it 'returns topic with case insensitive name' do
      %w[topic TOPIC Topic].each do |name|
        expect(described_class.find_by_name_case_insensitive(name)).to eq(topic)
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

  it_behaves_like Avatarable do
    let(:model) { create(:topic, :with_avatar) }
  end

  describe '#title_or_name' do
    it 'returns title if set' do
      topic.title = 'My title'
      expect(topic.title_or_name).to eq('My title')
    end

    it 'returns name if title not set' do
      topic.title = nil
      expect(topic.title_or_name).to eq('topic')
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns organization_id' do
      organization = build_stubbed(:organization)
      topic = build_stubbed(:topic, organization: organization)

      expect(topic.uploads_sharding_key).to eq(organization_id: organization.id)
    end
  end
end
