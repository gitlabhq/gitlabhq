# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Run do
  describe '.match' do
    it 'returns true for a run command' do
      expect(described_class.match('run foo')).to be_an_instance_of(MatchData)
    end

    it 'returns true for a run command with arguments' do
      expect(described_class.match('run foo bar baz'))
        .to be_an_instance_of(MatchData)
    end

    it 'returns true for a command containing newlines' do
      expect(described_class.match("run foo\nbar\nbaz"))
        .to be_an_instance_of(MatchData)
    end

    it 'returns false for an unrelated command' do
      expect(described_class.match('foo bar')).to be_nil
    end
  end

  describe '.available?' do
    it 'returns true when builds are enabled for the project' do
      project = double(:project, builds_enabled?: true)

      allow(Gitlab::Chat)
        .to receive(:available?)
        .and_return(true)

      expect(described_class.available?(project)).to eq(true)
    end

    it 'returns false when builds are disabled for the project' do
      project = double(:project, builds_enabled?: false)

      expect(described_class.available?(project)).to eq(false)
    end
  end

  describe '.allowed?' do
    it 'returns true when the user can create a pipeline' do
      project = create(:project)

      expect(described_class.allowed?(project, project.creator)).to eq(true)
    end

    it 'returns false when the user can not create a pipeline' do
      project = create(:project)
      user = create(:user)

      expect(described_class.allowed?(project, user)).to eq(false)
    end
  end

  describe '#execute' do
    let(:chat_name) { create(:chat_name) }
    let(:project) { create(:project) }

    let(:command) do
      described_class.new(project, chat_name, response_url: 'http://example.com')
    end

    context 'when a pipeline could not be scheduled' do
      it 'returns an error' do
        expect_next_instance_of(Gitlab::Chat::Command) do |instance|
          expect(instance).to receive(:try_create_pipeline).and_return(nil)
        end

        expect_next_instance_of(Gitlab::SlashCommands::Presenters::Run) do |instance|
          expect(instance).to receive(:failed_to_schedule).with('foo')
        end

        command.execute(command: 'foo', arguments: '')
      end
    end

    context 'when a pipeline could be created but the chat service was not supported' do
      it 'returns an error' do
        build = double(:build)
        pipeline = double(
          :pipeline,
          builds: double(:relation, take: build),
          persisted?: true
        )

        expect_next_instance_of(Gitlab::Chat::Command) do |instance|
          expect(instance).to receive(:try_create_pipeline).and_return(pipeline)
        end

        expect(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(nil)

        expect_next_instance_of(Gitlab::SlashCommands::Presenters::Run) do |instance|
          expect(instance).to receive(:unsupported_chat_service)
        end

        command.execute(command: 'foo', arguments: '')
      end
    end

    context 'using a valid pipeline' do
      it 'schedules the pipeline' do
        responder = double(:responder, scheduled_output: 'hello')
        build = double(:build)
        pipeline = double(
          :pipeline,
          builds: double(:relation, take: build),
          persisted?: true
        )

        expect_next_instance_of(Gitlab::Chat::Command) do |instance|
          expect(instance).to receive(:try_create_pipeline).and_return(pipeline)
        end

        expect(Gitlab::Chat::Responder)
          .to receive(:responder_for)
          .with(build)
          .and_return(responder)

        expect_next_instance_of(Gitlab::SlashCommands::Presenters::Run) do |instance|
          expect(instance).to receive(:in_channel_response).with(responder.scheduled_output)
        end

        command.execute(command: 'foo', arguments: '')
      end
    end
  end
end
