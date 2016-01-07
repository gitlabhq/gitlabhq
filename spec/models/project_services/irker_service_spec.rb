# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'
require 'socket'
require 'json'

describe IrkerService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    before do
      subject.active = true
      subject.properties['recipients'] = _recipients
    end

    context 'active' do
      let(:_recipients) { nil }
      it { should validate_presence_of :recipients }
    end
  end

  describe 'Execute' do
    let(:irker) { IrkerService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }

    let(:recipients) { '#commits irc://test.net/#test ftp://bad' }
    let(:colorize_messages) { '1' }

    before do
      allow(irker).to receive_messages(
        active: true,
        project: project,
        project_id: project.id,
        service_hook: true,
        server_host: 'localhost',
        server_port: 6659,
        default_irc_uri: 'irc://chat.freenode.net/',
        recipients: recipients,
        colorize_messages: colorize_messages)

      irker.valid?
      @irker_server = TCPServer.new 'localhost', 6659
    end

    after do
      @irker_server.close
    end

    it 'should send valid JSON messages to an Irker listener' do
      irker.execute(sample_data)

      conn = @irker_server.accept
      conn.readlines.each do |line|
        msg = JSON.load(line.chomp("\n"))
        expect(msg.keys).to match_array(['to', 'privmsg'])
        expect(msg['to']).to match_array(["irc://chat.freenode.net/#commits",
                                          "irc://test.net/#test"])
      end
      conn.close
    end
  end
end
