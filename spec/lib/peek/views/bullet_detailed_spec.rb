# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::BulletDetailed do
  subject { described_class.new }

  before do
    allow(Bullet).to receive(:enable?).and_return(bullet_enabled)
  end

  context 'bullet disabled' do
    let(:bullet_enabled) { false }

    it 'returns empty results' do
      expect(subject.results).to eq({})
    end
  end

  context 'bullet enabled' do
    let(:bullet_enabled) { true }

    before do
      allow(Bullet).to receive_message_chain(:notification_collector, :collection).and_return(notifications)
    end

    context 'where there are no notifications' do
      let(:notifications) { [] }

      it 'returns empty results' do
        expect(subject.results).to eq({})
      end
    end

    context 'when notifications exist' do
      let(:notifications) do
        [
          double(title: 'Title 1', body: 'Body 1', body_with_caller: "first\nsecond\n"),
          double(title: 'Title 2', body: 'Body 2', body_with_caller: "first\nsecond\n")
        ]
      end

      it 'returns empty results' do
        expect(subject.key).to eq('bullet')
        expect(subject.results[:calls]).to eq(2)
        expect(subject.results[:warnings]).to eq([Peek::Views::BulletDetailed::WARNING_MESSAGE])
        expect(subject.results[:details]).to eq(
          [
            { notification: 'Title 1: Body 1', backtrace: "first\nsecond\n" },
            { notification: 'Title 2: Body 2', backtrace: "first\nsecond\n" }
          ])
      end
    end
  end
end
