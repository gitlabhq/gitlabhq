# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::QuickActionsStatus, feature_category: :team_planning do
  let(:command_names) { %w[/assign /label] }
  let(:commands_only) { true }
  let(:status) { described_class.new(command_names: command_names, commands_only: commands_only) }

  describe '#add_message' do
    it 'adds a non-blank message to messages' do
      status.add_message('Test message')

      expect(status.messages).to eq(['Test message'])
    end

    it 'does not add a blank message' do
      status.add_message('')

      expect(status.messages).to be_empty
    end
  end

  describe '#add_error' do
    it 'adds an error message to error_messages' do
      status.add_error('Test error')

      expect(status.error_messages).to eq(['Test error'])
    end
  end

  describe '#commands_only?' do
    it 'returns the value of commands_only' do
      expect(status.commands_only?).to eq(commands_only)
    end
  end

  describe '#success?' do
    it 'returns true when there are no error messages' do
      expect(status.success?).to be true
    end

    it 'returns false when there are error messages' do
      status.add_error('Test error')

      expect(status.success?).to be false
    end
  end

  describe '#error?' do
    it 'returns false when there are no error messages' do
      expect(status.error?).to be false
    end

    it 'returns true when there are error messages' do
      status.add_error('Test error')

      expect(status.error?).to be true
    end
  end

  describe '#to_h' do
    context 'when there are no messages or errors' do
      it 'returns a hash with command_names and commands_only' do
        expect(status.to_h).to eq({
          command_names: command_names,
          commands_only: commands_only,
          messages: nil
        })
      end
    end

    context 'when there are messages' do
      before do
        status.add_message('Test message')
      end

      it 'includes messages in the hash' do
        expect(status.to_h).to eq({
          command_names: command_names,
          commands_only: commands_only,
          messages: ['Test message']
        })
      end
    end

    context 'when there are error messages' do
      before do
        status.add_error('Test error')
      end

      it 'includes error_messages in the hash' do
        expect(status.to_h).to eq({
          command_names: command_names,
          commands_only: commands_only,
          error_messages: ['Test error'],
          messages: nil
        })
      end
    end
  end
end
