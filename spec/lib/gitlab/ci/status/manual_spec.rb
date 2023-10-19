# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Status::Manual do
  subject do
    described_class.new(double('subject'), double('user'))
  end

  describe '#text' do
    it { expect(subject.text).to eq 'Manual' }
  end

  describe '#label' do
    it { expect(subject.label).to eq 'manual action' }
  end

  describe '#icon' do
    it { expect(subject.icon).to eq 'status_manual' }
  end

  describe '#favicon' do
    it { expect(subject.favicon).to eq 'favicon_status_manual' }
  end

  describe '#group' do
    it { expect(subject.group).to eq 'manual' }
  end
end
