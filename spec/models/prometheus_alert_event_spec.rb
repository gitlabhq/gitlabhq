# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAlertEvent do
  subject { build(:prometheus_alert_event) }

  let(:alert) { subject.prometheus_alert }

  describe 'associations' do
    it { is_expected.to belong_to(:prometheus_alert).required }
  end

  describe 'validations' do
    it { is_expected.to be_valid }

    it { is_expected.to validate_presence_of(:prometheus_alert).with_message(:required) }
    it { is_expected.to validate_uniqueness_of(:payload_key).scoped_to(:prometheus_alert_id) }
    it { is_expected.to validate_presence_of(:started_at) }

    describe 'payload_key & ended_at' do
      context 'absent if firing?' do
        subject { build(:prometheus_alert_event) }

        it { is_expected.to validate_presence_of(:payload_key) }
        it { is_expected.not_to validate_presence_of(:ended_at) }
      end

      context 'present if resolved?' do
        subject { build(:prometheus_alert_event, :resolved) }

        it { is_expected.not_to validate_presence_of(:payload_key) }
        it { is_expected.to validate_presence_of(:ended_at) }
      end
    end
  end

  describe '#title' do
    it 'delegates to alert' do
      expect(subject.title).to eq(alert.title)
    end
  end

  describe 'prometheus_metric_id' do
    it 'delegates to alert' do
      expect(subject.prometheus_metric_id).to eq(alert.prometheus_metric_id)
    end
  end

  describe 'transaction' do
    describe 'fire' do
      let(:started_at) { Time.current }

      context 'when status is none' do
        subject { build(:prometheus_alert_event, status: nil, started_at: nil) }

        it 'fires an event' do
          result = subject.fire(started_at)

          expect(result).to eq(true)
          expect(subject).to be_firing
          expect(subject.started_at).to be_like_time(started_at)
        end
      end

      context 'when firing' do
        subject { build(:prometheus_alert_event) }

        it 'cannot fire again' do
          result = subject.fire(started_at)

          expect(result).to eq(false)
        end
      end
    end

    describe 'resolve' do
      let(:ended_at) { Time.current }

      context 'when firing' do
        subject { build(:prometheus_alert_event) }

        it 'resolves an event' do
          result = subject.resolve!(ended_at)

          expect(result).to eq(true)
          expect(subject).to be_resolved
          expect(subject.ended_at).to be_like_time(ended_at)
        end
      end

      context 'when resolved' do
        subject { build(:prometheus_alert_event, :resolved) }

        it 'cannot resolve again' do
          result = subject.resolve(ended_at)

          expect(result).to eq(false)
        end
      end
    end
  end
end
