# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Lograge::CustomOptions do
  describe '.call' do
    let(:params) do
      {
        'controller' => 'ApplicationController',
        'action' => 'show',
        'format' => 'html',
        'a' => 'b'
      }
    end

    let(:event) do
      ActiveSupport::Notifications::Event.new(
        'test',
        1,
        2,
        'transaction_id',
        { params: params, user_id: 'test' }
      )
    end

    subject { described_class.call(event) }

    it 'ignores some parameters' do
      param_keys = subject[:params].map { |param| param[:key] }

      expect(param_keys).not_to include(*described_class::IGNORE_PARAMS)
    end

    it 'formats the parameters' do
      expect(subject[:params]).to eq([{ key: 'a', value: 'b' }])
    end

    it 'adds the current time' do
      travel_to(5.days.ago) do
        expected_time = Time.now.utc.iso8601(3)

        expect(subject[:time]).to eq(expected_time)
      end
    end

    it 'adds the user id' do
      expect(subject[:user_id]).to eq('test')
    end
  end
end
