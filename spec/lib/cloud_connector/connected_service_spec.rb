# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe CloudConnector::ConnectedService, feature_category: :cloud_connector do
  describe '#free_access?' do
    let(:service) { described_class.new(name: :code_suggestions, cut_off_date: cut_off_date) }

    subject { service.free_access? }

    context 'when the service cut off date is in the past' do
      let(:cut_off_date) { Time.current - 1.second }

      it { is_expected.to eq(false) }
    end

    context 'when the service cut off date is in the future' do
      let(:cut_off_date) { Time.current + 1.second }

      it { is_expected.to eq(true) }
    end

    context 'when the service cut off date is nil' do
      let(:cut_off_date) { nil }

      it { is_expected.to eq(true) }
    end
  end
end
