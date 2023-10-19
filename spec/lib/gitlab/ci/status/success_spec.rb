# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Success do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Passed' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'passed' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_success' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_success' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'success' }
  end

  describe '#details_path' do
    it { expect(subject.details_path).to be_nil }
  end
end
