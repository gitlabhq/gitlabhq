# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Auth::Activity do
  describe '.each_counter' do
    it 'has all static counters defined' do
      described_class.each_counter do |counter|
        expect(described_class).to respond_to(counter)
      end
    end

    it 'has all static incrementers defined' do
      described_class.each_counter do |counter|
        expect(described_class).to respond_to("#{counter}_increment!")
      end
    end

    it 'has all counters starting with `user_`' do
      described_class.each_counter do |counter|
        expect(counter).to start_with('user_')
      end
    end

    it 'yields counter method, name and description' do
      described_class.each_counter do |method, name, description|
        expect(method).to eq "#{name}_counter"
        expect(description).to start_with('Counter of')
      end
    end
  end
end
