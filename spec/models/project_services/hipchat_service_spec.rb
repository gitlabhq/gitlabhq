# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HipchatService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
    end
  end

  describe "Execute" do
    let(:hipchat) { described_class.new }
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:api_url) { 'https://hipchat.example.com/v2/room/123456/notification?auth_token=verySecret' }
    let(:project_name) { project.full_name.gsub(/\s/, '') }
    let(:token) { 'verySecret' }
    let(:server_url) { 'https://hipchat.example.com'}
    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    before do
      allow(hipchat).to receive_messages(
        project_id: project.id,
        project: project,
        room: 123456,
        server: server_url,
        token: token
      )
      WebMock.stub_request(:post, api_url)
    end

    it 'does nothing' do
      expect { hipchat.execute(push_sample_data) }.not_to raise_error
    end

    describe "#message_options" do
      it "is set to the defaults" do
        expect(hipchat.__send__(:message_options)).to eq({ notify: false, color: 'yellow' })
      end

      it "sets notify to true" do
        allow(hipchat).to receive(:notify).and_return('1')

        expect(hipchat.__send__(:message_options)).to eq({ notify: true, color: 'yellow' })
      end

      it "sets the color" do
        allow(hipchat).to receive(:color).and_return('red')

        expect(hipchat.__send__(:message_options)).to eq({ notify: false, color: 'red' })
      end

      context 'with a successful build' do
        it 'uses the green color' do
          data = { object_kind: 'pipeline',
                   object_attributes: { status: 'success' } }

          expect(hipchat.__send__(:message_options, data)).to eq({ notify: false, color: 'green' })
        end
      end

      context 'with a failed build' do
        it 'uses the red color' do
          data = { object_kind: 'pipeline',
                   object_attributes: { status: 'failed' } }

          expect(hipchat.__send__(:message_options, data)).to eq({ notify: false, color: 'red' })
        end
      end
    end
  end
end
