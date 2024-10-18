# frozen_string_literal: true

RSpec.shared_examples 'unlicensed cycle analytics request params' do
  let(:params) do
    {
      created_after: '2019-01-01',
      created_before: '2019-03-01',
      project_ids: [2, 3],
      namespace: namespace,
      current_user: user
    }
  end

  let(:request_params) { described_class.new(params) }

  subject { request_params }

  before do
    root_group.add_owner(user)
  end

  describe 'validations' do
    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'when `created_before` is missing' do
      before do
        params[:created_before] = nil
      end

      it 'is valid', time_travel_to: '2019-03-01' do
        expect(subject).to be_valid
      end
    end

    context 'when `created_before` is earlier than `created_after`' do
      before do
        params[:created_before] = '2015-01-01'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:created_before]).not_to be_empty
      end
    end

    context 'when the date range is exactly 180 days' do
      before do
        params[:created_before] = '2019-06-30'
      end

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when the date range exceeds 180 days' do
      before do
        params[:created_before] = '2019-07-01'
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        message = s_('CycleAnalytics|The given date range is larger than 180 days')
        expect(subject.errors.messages[:created_after]).to include(message)
      end
    end
  end

  it 'casts `created_after` to `Time`' do
    expect(subject.created_after).to be_a_kind_of(Time)
  end

  it 'casts `created_before` to `Time`' do
    expect(subject.created_before).to be_a_kind_of(Time)
  end

  describe 'optional `value_stream`' do
    context 'when `value_stream` is not empty' do
      let(:value_stream) { instance_double('Analytics::CycleAnalytics::ValueStream') }

      before do
        params[:value_stream] = value_stream
      end

      it { expect(subject.value_stream).to eq(value_stream) }
    end

    context 'when `value_stream` is nil' do
      before do
        params[:value_stream] = nil
      end

      it { expect(subject.value_stream).to eq(nil) }
    end
  end

  describe 'sorting params' do
    before do
      params.merge!(sort: 'duration', direction: 'asc')
    end

    it 'converts sorting params to symbol when passing it to data collector' do
      data_collector_params = subject.to_data_collector_params

      expect(data_collector_params[:sort]).to eq(:duration)
      expect(data_collector_params[:direction]).to eq(:asc)
    end

    it 'adds sorting params to data attributes' do
      data_attributes = subject.to_data_attributes

      expect(data_attributes[:sort]).to eq('duration')
      expect(data_attributes[:direction]).to eq('asc')
    end
  end

  describe 'aggregation params' do
    context 'when not licensed' do
      it 'returns nil' do
        data_collector_params = subject.to_data_attributes
        expect(data_collector_params[:aggregation]).to eq(nil)
      end
    end
  end

  describe 'use_aggregated_data_collector param' do
    subject(:value) { request_params.to_data_collector_params[:use_aggregated_data_collector] }

    it { is_expected.to eq(false) }
  end

  describe 'feature availablity data attributes' do
    subject(:value) { request_params.to_data_attributes }

    it 'disables all paid features' do
      is_expected.to match(a_hash_including(enable_tasks_by_type_chart: 'false',
        enable_customizable_stages: 'false',
        enable_projects_filter: 'false',
        enable_vsd_link: 'false'
      ))
    end
  end

  describe '#to_data_collector_params' do
    context 'when adding licensed parameters' do
      subject(:data_collector_params) { request_params.to_data_collector_params }

      before do
        params.merge!(
          weight: 1,
          epic_id: 2,
          iteration_id: 3,
          my_reaction_emoji: AwardEmoji::THUMBS_UP,
          not: { assignee_username: 'test' }
        )
      end

      it 'excludes the attributes from the data collector params' do
        expect(data_collector_params).to exclude(:weight)
        expect(data_collector_params).to exclude(:epic_id)
        expect(data_collector_params).to exclude(:iteration_id)
        expect(data_collector_params).to exclude(:my_reaction_emoji)
        expect(data_collector_params).to exclude(:not)
      end
    end
  end
end
