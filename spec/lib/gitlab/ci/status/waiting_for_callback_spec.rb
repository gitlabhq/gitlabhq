# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::WaitingForCallback, feature_category: :deployment_management do
  subject do
    described_class.new(double, double)
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Waiting' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'waiting for callback' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_pending' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_pending' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'waiting-for-callback' }
  end

  describe '#name' do
    it { expect(subject.name).to eq 'WAITING_FOR_CALLBACK' }
  end

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
