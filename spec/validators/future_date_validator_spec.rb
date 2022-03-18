# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FutureDateValidator do
  subject do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :expires_at

      validates :expires_at, future_date: true
    end.new
  end

  before do
    subject.expires_at = date
  end

  context 'past date' do
    let(:date) { Date.yesterday }

    it { is_expected.not_to be_valid }
  end

  context 'current date' do
    let(:date) { Date.today }

    it { is_expected.to be_valid }
  end

  context 'future date' do
    let(:date) { Date.tomorrow }

    it { is_expected.to be_valid }
  end
end
