# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ValueStream, type: :model, feature_category: :value_stream_management do
  describe 'associations' do
    it { is_expected.to belong_to(:namespace).required }
    it { is_expected.to have_many(:stages) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it 'validates uniqueness of name' do
      group = create(:group)
      create(:cycle_analytics_value_stream, name: 'test', namespace: group)

      value_stream = build(:cycle_analytics_value_stream, name: 'test', namespace: group)

      expect(value_stream).to be_invalid
      expect(value_stream.errors.messages).to eq(name: [I18n.t('errors.messages.taken')])
    end

    it_behaves_like 'value stream analytics namespace models' do
      let(:factory_name) { :cycle_analytics_value_stream }
    end

    it 'validates count of value streams per namespace' do
      stub_const("#{described_class.name}::MAX_VALUE_STREAMS_PER_NAMESPACE", 1)
      group = create(:group)
      create(:cycle_analytics_value_stream, name: 'test', namespace: group)

      new_value_stream = build(:cycle_analytics_value_stream, name: 'test2', namespace: group)

      expect do
        new_value_stream.save!
      end.to raise_error(ActiveRecord::RecordInvalid,
        _('Validation failed: Namespace Maximum number of value streams per namespace exceeded'))
    end
  end

  describe 'scopes' do
    let_it_be(:group) { create(:group) }

    describe '.order_by_name_asc' do
      let_it_be(:stream1) { create(:cycle_analytics_value_stream, namespace: group, name: 'Bbb') }
      let_it_be(:stream2) { create(:cycle_analytics_value_stream, namespace: group, name: 'aaa') }
      let_it_be(:stream3) { create(:cycle_analytics_value_stream, namespace: group, name: 'Aaa') }

      it 'returns in case-insensitive alphabetical order' do
        expect(described_class.order_by_name_asc).to eq [stream2, stream3, stream1]
      end
    end
  end

  describe 'ordering of stages' do
    let(:group) { create(:group, :with_organization) }
    let(:value_stream) do
      create(:cycle_analytics_value_stream, namespace: group, stages: [
        create(:cycle_analytics_stage, namespace: group, name: "stage 1", relative_position: 5),
        create(:cycle_analytics_stage, namespace: group, name: "stage 2", relative_position: nil),
        create(:cycle_analytics_stage, namespace: group, name: "stage 3", relative_position: 1)
      ])
    end

    before do
      value_stream.reload
    end

    describe 'stages attribute' do
      it 'sorts stages by relative position' do
        names = value_stream.stages.map(&:name)
        expect(names).to eq(['stage 3', 'stage 1', 'stage 2'])
      end
    end
  end

  describe '#custom?' do
    context 'when value stream is not persisted' do
      subject(:value_stream) { build(:cycle_analytics_value_stream, name: value_stream_name) }

      context 'when the name of the value stream is default' do
        let(:value_stream_name) { Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME }

        it { is_expected.not_to be_custom }
      end

      context 'when the name of the value stream is not default' do
        let(:value_stream_name) { 'value_stream_1' }

        it { is_expected.to be_custom }
      end
    end

    context 'when value stream is persisted' do
      subject(:value_stream) { create(:cycle_analytics_value_stream, name: 'value_stream_1') }

      it { is_expected.to be_custom }
    end
  end

  describe '#project' do
    subject(:value_stream) do
      build(:cycle_analytics_value_stream, name: 'value_stream_1', namespace: namespace).project
    end

    context 'when namespace is a project' do
      let_it_be(:project) { create(:project) }
      let(:namespace) { project.project_namespace }

      it { is_expected.to eq(project) }
    end

    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group) }

      it { is_expected.to be_nil }
    end
  end
end
