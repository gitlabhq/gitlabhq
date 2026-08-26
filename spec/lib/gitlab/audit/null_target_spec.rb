# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Audit::NullTarget do
  subject { described_class.new }

  describe '#id' do
    it 'returns nil' do
      expect(subject.id).to be_nil
    end
  end

  describe '#type' do
    it 'returns nil' do
      expect(subject.type).to be_nil
    end
  end

  describe '#details' do
    it 'returns nil' do
      expect(subject.details).to be_nil
    end
  end
end
