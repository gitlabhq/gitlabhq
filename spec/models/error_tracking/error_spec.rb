# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Error, type: :model do
  let_it_be(:error) { create(:error_tracking_error) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:events) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
    it { is_expected.to validate_presence_of(:actor) }
    it { is_expected.to validate_length_of(:actor).is_at_most(255) }
    it { is_expected.to validate_length_of(:platform).is_at_most(255) }
  end

  describe '.report_error' do
    it 'updates existing record with a new timestamp' do
      timestamp = Time.zone.now

      reported_error = described_class.report_error(
        name: error.name,
        description: 'Lorem ipsum',
        actor: error.actor,
        platform: error.platform,
        timestamp: timestamp
      )

      expect(reported_error.id).to eq(error.id)
      expect(reported_error.last_seen_at).to eq(timestamp)
      expect(reported_error.description).to eq('Lorem ipsum')
    end
  end

  describe '.sort_by_attribute' do
    let!(:error2) { create(:error_tracking_error, first_seen_at: Time.zone.now - 2.weeks, last_seen_at: Time.zone.now - 1.week) }
    let!(:error3) { create(:error_tracking_error, first_seen_at: Time.zone.now - 3.weeks, last_seen_at: Time.zone.now.yesterday) }
    let!(:errors) { [error, error2, error3] }

    subject { described_class.where(id: errors).sort_by_attribute(sort) }

    context 'id desc by default' do
      let(:sort) { nil }

      it { is_expected.to eq([error3, error2, error]) }
    end

    context 'first_seen' do
      let(:sort) { 'first_seen' }

      it { is_expected.to eq([error, error2, error3]) }
    end

    context 'last_seen' do
      let(:sort) { 'last_seen' }

      it { is_expected.to eq([error, error3, error2]) }
    end

    context 'frequency' do
      let(:sort) { 'frequency' }

      before do
        create(:error_tracking_error_event, error: error2)
        create(:error_tracking_error_event, error: error2)
        create(:error_tracking_error_event, error: error3)
      end

      it { is_expected.to eq([error2, error3, error]) }
    end
  end

  describe '#title' do
    it { expect(error.title).to eq('ActionView::MissingTemplate Missing template posts/edit') }
  end

  describe '#to_sentry_error' do
    it { expect(error.to_sentry_error).to be_kind_of(Gitlab::ErrorTracking::Error) }
  end

  describe '#to_sentry_detailed_error' do
    let_it_be(:event) { create(:error_tracking_error_event, error: error) }

    subject { error.to_sentry_detailed_error }

    it { is_expected.to be_kind_of(Gitlab::ErrorTracking::DetailedError) }
    it { expect(subject.integrated).to be_truthy }
    it { expect(subject.first_release_version).to eq('db853d7') }
    it { expect(subject.last_release_version).to eq('db853d7') }
  end
end
