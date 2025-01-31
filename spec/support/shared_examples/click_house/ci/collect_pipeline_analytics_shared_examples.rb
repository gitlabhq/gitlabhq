# frozen_string_literal: true

RSpec.shared_examples_for 'a pipeline analytics service' do
  context 'when ClickHouse database is not configured' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(false)
    end

    it 'returns error' do
      expect(result.error?).to be true
      expect(result.errors).to contain_exactly('ClickHouse database is not configured')
    end
  end

  shared_examples 'returns Not allowed error' do
    it 'returns error' do
      expect(result.error?).to be true
      expect(result.errors).to contain_exactly('Not allowed')
    end
  end

  context 'when user is nil' do
    let(:current_user) { nil }

    include_examples 'returns Not allowed error'
  end

  context 'when user is a guest' do
    let_it_be(:current_user) { create(:user, guest_of: project1) }

    include_examples 'returns Not allowed error'
  end

  context 'when project has analytics disabled' do
    let_it_be(:project) { create(:project, :analytics_disabled) }

    include_examples 'returns Not allowed error'
  end

  context 'when ClickHouse query raises error' do
    before do
      allow(::ClickHouse::Client).to receive(:select).with(anything, :main)
        .and_raise(::ClickHouse::Client::DatabaseError, 'some error')
    end

    it 'returns error response', :aggregate_failures do
      expect { result }.not_to raise_error
      expect(result.error?).to be true
      expect(result.errors).to contain_exactly('some error')
    end
  end

  context 'when project is not specified' do
    let(:project) { nil }

    it 'returns error response', :aggregate_failures do
      expect(result.error?).to be true
      expect(result.errors).to contain_exactly('Project must be specified')
    end
  end

  context 'when invalid duration percentiles are specified' do
    let(:duration_percentiles) { [50, 70, 90] }

    it 'returns error response', :aggregate_failures do
      expect(result.error?).to be true
      expect(result.message).to eq 'Invalid duration percentiles specified'
    end
  end

  context 'when from_date is more recent than to_date' do
    let(:from_time) { 1.day.ago }
    let(:to_time) { 2.days.ago }

    it 'returns error', :aggregate_failures do
      expect(result.error?).to be true
      expect(result.message).to eq 'Invalid time window'
    end
  end
end
