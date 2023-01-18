# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'menu item shows pill based on count' do |count|
  describe '#has_pill?' do
    context 'when count is zero' do
      it 'returns false' do
        allow(user).to receive(count).and_return(0)
        expect(subject.has_pill?).to eq false
      end
    end

    context 'when count is larger than zero' do
      it 'returns true' do
        allow(user).to receive(count).and_return(3)
        expect(subject.has_pill?).to eq true
      end
    end
  end

  describe '#pill_count' do
    it "returns the #{count} of the user" do
      allow(user).to receive(count).and_return(123)
      expect(subject.pill_count).to eq 123
    end

    it 'memoizes the query' do
      subject.pill_count

      control = ActiveRecord::QueryRecorder.new do
        subject.pill_count
      end

      expect(control.count).to eq 0
    end
  end
end
