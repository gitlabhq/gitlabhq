require 'spec_helper'

describe EE::NotificationService do
  let(:subject) { NotificationService.new }

  before do
    allow(Notify).to receive(:service_desk_new_note_email)
      .with(kind_of(Integer), kind_of(Integer)).and_return(double(deliver_later: true))

    allow_any_instance_of(License).to receive(:feature_available?).and_call_original
    allow_any_instance_of(License).to receive(:feature_available?).with(:service_desk) { true }
    allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
  end

  def should_email!
    expect(Notify).to receive(:service_desk_new_note_email).with(issue.id, kind_of(Integer))
  end

  def should_not_email!
    expect(Notify).not_to receive(:service_desk_new_note_email)
  end

  def execute!
    subject.send_service_desk_notification(note)
  end

  def self.it_should_email!
    it 'sends the email' do
      should_email!
      execute!
    end
  end

  def self.it_should_not_email!
    it 'doesn\'t send the email' do
      should_not_email!
      execute!
    end
  end

  let(:issue) { create(:issue, author: User.support_bot) }
  let(:project) { issue.project }
  let(:note) { create(:note, noteable: issue, project: project) }

  context 'a non-service-desk issue' do
    it_should_not_email!
  end

  context 'a service-desk issue' do
    before do
      issue.update!(service_desk_reply_to: 'service.desk@example.com')
      project.update!(service_desk_enabled: true)
    end

    it_should_email!

    context 'where the project has disabled the feature' do
      before do
        project.update(service_desk_enabled: false)
      end

      it_should_not_email!
    end

    context 'when the license doesn\'t allow service desk' do
      before do
        expect(EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
      end

      it_should_not_email!
    end

    context 'when the support bot has unsubscribed' do
      before do
        issue.unsubscribe(User.support_bot, project)
      end

      it_should_not_email!
    end
  end
end
