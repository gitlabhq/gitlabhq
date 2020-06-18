# frozen_string_literal: true

require 'spec_helper'

describe IrkerWorker, '#perform' do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:push_data) { HashWithIndifferentAccess.new(Gitlab::DataBuilder::Push.build_sample(project, user)) }
  let_it_be(:channels) { ['irc://test.net/#test'] }

  let_it_be(:server_settings) do
    {
      server_host: 'localhost',
      server_port: 6659
    }
  end

  let_it_be(:arguments) do
    [
      project.id,
      channels,
      false,
      push_data,
      server_settings
    ]
  end

  let(:tcp_socket) { double('socket') }

  subject(:worker) { described_class.new }

  before do
    allow(TCPSocket).to receive(:new).and_return(tcp_socket)
    allow(tcp_socket).to receive(:puts).and_return(true)
    allow(tcp_socket).to receive(:close).and_return(true)
  end

  context 'connection fails' do
    before do
      allow(TCPSocket).to receive(:new).and_raise(Errno::ECONNREFUSED.new('test'))
    end

    it { expect(subject.perform(*arguments)).to be_falsey }
  end

  context 'connection successful' do
    it { expect(subject.perform(*arguments)).to be_truthy }

    context 'new branch' do
      it 'sends a correct message with branches url' do
        branches_url = Gitlab::Routing.url_helpers
          .project_branches_url(project)

        push_data['before'] = '0000000000000000000000000000000000000000'

        message = "has created a new branch master: #{branches_url}"

        expect(tcp_socket).to receive(:puts).with(wrap_message(message))

        subject.perform(*arguments)
      end
    end

    context 'deleted branch' do
      it 'sends a correct message' do
        push_data['after'] = '0000000000000000000000000000000000000000'

        message = "has deleted the branch master"

        expect(tcp_socket).to receive(:puts).with(wrap_message(message))

        subject.perform(*arguments)
      end
    end

    context 'new commits to existing branch' do
      it 'sends a correct message with a compare url' do
        compare_url = Gitlab::Routing.url_helpers
          .project_compare_url(project,
                               from: Commit.truncate_sha(push_data[:before]),
                               to: Commit.truncate_sha(push_data[:after]))

        message = "pushed #{push_data['total_commits_count']} " \
          "new commits to master: #{compare_url}"

        expect(tcp_socket).to receive(:puts).with(wrap_message(message))

        subject.perform(*arguments)
      end
    end
  end

  def wrap_message(text)
    message = "[#{project.path}] #{push_data['user_name']} #{text}"
    to_send = { to: channels, privmsg: message }

    Gitlab::Json.dump(to_send)
  end
end
