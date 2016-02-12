shared_context 'gitlab email notification' do
  let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
  let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
  let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
  let(:recipient) { create(:user, email: 'recipient@example.com') }
  let(:project) { create(:project) }
  let(:new_user_address) { 'newguy@example.com' }

  before do
    ActionMailer::Base.deliveries.clear
    email = recipient.emails.create(email: "notifications@example.com")
    recipient.update_attribute(:notification_email, email.email)
  end
end

shared_examples 'a multiple recipients email' do
  it 'is sent to the given recipient' do
    is_expected.to deliver_to recipient.notification_email
  end
end

shared_examples 'an email sent from GitLab' do
  it 'is sent from GitLab' do
    sender = subject.header[:from].addrs[0]
    expect(sender.display_name).to eq(gitlab_sender_display_name)
    expect(sender.address).to eq(gitlab_sender)
  end

  it 'has a Reply-To address' do
    reply_to = subject.header[:reply_to].addresses
    expect(reply_to).to eq([gitlab_sender_reply_to])
  end
end

shared_examples 'an email that contains a header with author username' do
  it 'has X-GitLab-Author header containing author\'s username' do
    is_expected.to have_header 'X-GitLab-Author', user.username
  end
end

shared_examples 'an email with X-GitLab headers containing project details' do
  it 'has X-GitLab-Project* headers' do
    is_expected.to have_header 'X-GitLab-Project', /#{project.name}/
    is_expected.to have_header 'X-GitLab-Project-Id', /#{project.id}/
    is_expected.to have_header 'X-GitLab-Project-Path', /#{project.path_with_namespace}/
  end
end

shared_examples 'an email starting a new thread' do |message_id_prefix|
  include_examples 'an email with X-GitLab headers containing project details'

  it 'has a discussion identifier' do
    is_expected.to have_header 'Message-ID',  /<#{message_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
  end
end

shared_examples 'an answer to an existing thread' do |thread_id_prefix|
  include_examples 'an email with X-GitLab headers containing project details'

  it 'has a subject that begins with Re: ' do
    is_expected.to have_subject /^Re: /
  end

  it 'has headers that reference an existing thread' do
    is_expected.to have_header 'Message-ID',  /<(.*)@#{Gitlab.config.gitlab.host}>/
    is_expected.to have_header 'References',  /<#{thread_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
    is_expected.to have_header 'In-Reply-To', /<#{thread_id_prefix}(.*)@#{Gitlab.config.gitlab.host}>/
  end
end

shared_examples 'a new user email' do
  it 'is sent to the new user' do
    is_expected.to deliver_to new_user_address
  end

  it 'has the correct subject' do
    is_expected.to have_subject /^Account was created for you$/i
  end

  it 'contains the new user\'s login name' do
    is_expected.to have_body_text /#{new_user_address}/
  end
end

shared_examples 'it should have Gmail Actions links' do
  it { is_expected.to have_body_text /ViewAction/ }
end

shared_examples 'it should not have Gmail Actions links' do
  it { is_expected.to_not have_body_text /ViewAction/ }
end

shared_examples 'it should show Gmail Actions View Issue link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text /View Issue/ }
end

shared_examples 'it should show Gmail Actions View Merge request link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text /View Merge request/ }
end

shared_examples 'it should show Gmail Actions View Commit link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text /View Commit/ }
end

shared_examples 'an unsubscribeable thread' do
  it { is_expected.to have_body_text /unsubscribe/ }
end

shared_examples "a user cannot unsubscribe through footer link" do
  it { is_expected.not_to have_body_text /unsubscribe/ }
end
