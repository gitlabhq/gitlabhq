# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Sidebars::Concerns::HasAvatar, feature_category: :navigation do
  subject do
    Class.new do
      include Sidebars::Concerns::HasAvatar
    end.new
  end

  describe '#avatar' do
    it 'returns nil' do
      expect(subject.avatar).to be_nil
    end
  end

  describe '#avatar_shape' do
    it 'returns rect' do
      expect(subject.avatar_shape).to eq('rect')
    end
  end

  describe '#entity_id' do
    it 'returns nil' do
      expect(subject.entity_id).to be_nil
    end
  end
end
