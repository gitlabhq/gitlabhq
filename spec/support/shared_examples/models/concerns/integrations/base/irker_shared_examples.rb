# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'json'

RSpec.shared_examples Integrations::Base::Irker do
  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  describe 'Execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:irker) { described_class.new }
    let(:irker_server) { TCPServer.new('localhost', 0) }
    let(:sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:recipients) { '#commits irc://test.net/#test ftp://bad' }
    let(:colorize_messages) { '1' }

    before do
      allow(Gitlab::CurrentSettings)
        .to receive(:allow_local_requests_from_web_hooks_and_services?)
        .and_return(true)

      allow(irker).to receive_messages(
        active: true,
        project: project,
        project_id: project.id,
        server_host: irker_server.addr[2],
        server_port: irker_server.addr[1],
        default_irc_uri: 'irc://chat.freenode.net/',
        recipients: recipients,
        colorize_messages: colorize_messages
      )

      irker.valid?
    end

    after do
      irker_server.close
    end

    it 'sends valid JSON messages to an Irker listener', :sidekiq_might_not_need_inline do
      expect(Integrations::IrkerWorker)
        .to receive(:perform_async)
        .with(project.id, irker.channels, colorize_messages, sample_data.deep_stringify_keys, irker.settings)
        .and_call_original

      irker.execute(sample_data)

      conn = irker_server.accept

      Timeout.timeout(5) do
        conn.each_line do |line|
          msg = Gitlab::Json.parse(line.chomp("\n"))
          expect(msg.keys).to match_array(%w[to privmsg])
          expect(msg['to'])
            .to match_array(%w[irc://chat.freenode.net/#commits irc://test.net/#test])
        end
      end
    ensure
      conn.close if conn
    end
  end
end
