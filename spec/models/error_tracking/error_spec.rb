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
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:actor) }
  end

  describe '#title' do
    it { expect(error.title).to eq('ActionView::MissingTemplate Missing template posts/edit') }
  end

  describe '#to_sentry_error' do
    it { expect(error.to_sentry_error).to be_kind_of(Gitlab::ErrorTracking::Error) }
  end

  describe '#to_sentry_detailed_error' do
    it { expect(error.to_sentry_detailed_error).to be_kind_of(Gitlab::ErrorTracking::DetailedError) }
  end
end
