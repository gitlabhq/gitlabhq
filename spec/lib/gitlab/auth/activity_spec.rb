# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Activity, feature_category: :system_access do
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

  describe '#user_csrf_token_mismatch!' do
    context 'when GraphQL controller is being used' do
      it 'increments correct counter with GraphQL label' do
        metrics = described_class.new(controller: GraphqlController.new)

        expect(described_class.user_csrf_token_invalid_counter)
          .to receive(:increment).with(controller: 'GraphqlController', auth: 'other')

        metrics.user_csrf_token_mismatch!
      end
    end

    context 'when another controller is being used' do
      it 'increments correct count with a non-specific label' do
        metrics = described_class.new(controller: ApplicationController.new)

        expect(described_class.user_csrf_token_invalid_counter)
          .to receive(:increment).with(controller: 'other', auth: 'other')

        metrics.user_csrf_token_mismatch!
      end
    end
  end
end
