shared_context 'gitlab email notification' do
  set(:project) { create(:project, :repository) }
  set(:recipient) { create(:user, email: 'recipient@example.com') }

  let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
  let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
  let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
  let(:new_user_address) { 'newguy@example.com' }

  before do
    email = recipient.emails.create(email: "notifications@example.com")
    recipient.update_attribute(:notification_email, email.email)
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@#{Gitlab.config.gitlab.host}")
  end
end

shared_context 'reply-by-email is enabled with incoming address without %{key}' do
  before do
    stub_incoming_email_setting(enabled: true, address: "reply@#{Gitlab.config.gitlab.host}")
  end
end

shared_examples 'a multiple recipients email' do
  it 'is sent to the given recipient' do
    is_expected.to deliver_to recipient.notification_email
  end
end

shared_examples 'an email sent from GitLab' do
  it 'has the characteristics of an email sent from GitLab' do
    sender = subject.header[:from].addrs[0]
    reply_to = subject.header[:reply_to].addresses

    aggregate_failures do
      expect(sender.display_name).to eq(gitlab_sender_display_name)
      expect(sender.address).to eq(gitlab_sender)
      expect(reply_to).to eq([gitlab_sender_reply_to])
    end
  end
end

shared_examples 'an email that contains a header with author username' do
  it 'has X-GitLab-Author header containing author\'s username' do
    is_expected.to have_header 'X-GitLab-Author', user.username
  end
end

shared_examples 'an email with X-GitLab headers containing project details' do
  it 'has X-GitLab-Project headers' do
    aggregate_failures do
      is_expected.to have_header('X-GitLab-Project', /#{project.name}/)
      is_expected.to have_header('X-GitLab-Project-Id', /#{project.id}/)
      is_expected.to have_header('X-GitLab-Project-Path', /#{project.full_path}/)
    end
  end
end

shared_examples 'a new thread email with reply-by-email enabled' do
  it 'has the characteristics of a threaded email' do
    host = Gitlab.config.gitlab.host
    route_key = "#{model.class.model_name.singular_route_key}_#{model.id}"

    aggregate_failures do
      is_expected.to have_header('Message-ID', "<#{route_key}@#{host}>")
      is_expected.to have_header('References', /\A<reply\-.*@#{host}>\Z/ )
    end
  end
end

shared_examples 'a thread answer email with reply-by-email enabled' do
  include_examples 'an email with X-GitLab headers containing project details'

  it 'has the characteristics of a threaded reply' do
    host = Gitlab.config.gitlab.host
    route_key = "#{model.class.model_name.singular_route_key}_#{model.id}"

    aggregate_failures do
      is_expected.to have_header('Message-ID', /\A<.*@#{host}>\Z/)
      is_expected.to have_header('In-Reply-To', "<#{route_key}@#{host}>")
      is_expected.to have_header('References',  /\A<#{route_key}@#{host}> <reply\-.*@#{host}>\Z/ )
      is_expected.to have_subject(/^Re: /)
    end
  end
end

shared_examples 'an email starting a new thread with reply-by-email enabled' do
  include_examples 'an email with X-GitLab headers containing project details'
  include_examples 'a new thread email with reply-by-email enabled'

  context 'when reply-by-email is enabled with incoming address with %{key}' do
    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
    end
  end

  context 'when reply-by-email is enabled with incoming address without %{key}' do
    include_context 'reply-by-email is enabled with incoming address without %{key}'
    include_examples 'a new thread email with reply-by-email enabled'

    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply@#{Gitlab.config.gitlab.host}>\Z/
    end
  end
end

shared_examples 'an answer to an existing thread with reply-by-email enabled' do
  include_examples 'an email with X-GitLab headers containing project details'
  include_examples 'a thread answer email with reply-by-email enabled'

  context 'when reply-by-email is enabled with incoming address with %{key}' do
    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
    end
  end

  context 'when reply-by-email is enabled with incoming address without %{key}' do
    include_context 'reply-by-email is enabled with incoming address without %{key}'
    include_examples 'a thread answer email with reply-by-email enabled'

    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply@#{Gitlab.config.gitlab.host}>\Z/
    end
  end
end

shared_examples 'it should have Gmail Actions links' do
  it do
    aggregate_failures do
      is_expected.to have_body_text('<script type="application/ld+json">')
      is_expected.to have_body_text('ViewAction')
    end
  end
end

shared_examples 'it should not have Gmail Actions links' do
  it do
    aggregate_failures do
      is_expected.not_to have_body_text('<script type="application/ld+json">')
      is_expected.not_to have_body_text('ViewAction')
    end
  end
end

shared_examples 'it should show Gmail Actions View Issue link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('View Issue') }
end

shared_examples 'it should show Gmail Actions View Merge request link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('View Merge request') }
end

shared_examples 'it should show Gmail Actions View Commit link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('View Commit') }
end

shared_examples 'an unsubscribeable thread' do
  it_behaves_like 'an unsubscribeable thread with incoming address without %{key}'

  it 'has a List-Unsubscribe header in the correct format, and a body link' do
    aggregate_failures do
      is_expected.to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.to have_header('List-Unsubscribe', /mailto/)
      is_expected.to have_header('List-Unsubscribe', /^<.+,.+>$/)
      is_expected.to have_body_text('unsubscribe')
    end
  end
end

shared_examples 'an unsubscribeable thread with incoming address without %{key}' do
  include_context 'reply-by-email is enabled with incoming address without %{key}'

  it 'has a List-Unsubscribe header in the correct format, and a body link' do
    aggregate_failures do
      is_expected.to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.not_to have_header('List-Unsubscribe', /mailto/)
      is_expected.to have_header('List-Unsubscribe', /^<[^,]+>$/)
      is_expected.to have_body_text('unsubscribe')
    end
  end
end

shared_examples 'a user cannot unsubscribe through footer link' do
  it 'does not have a List-Unsubscribe header or a body link' do
    aggregate_failures do
      is_expected.not_to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.not_to have_body_text('unsubscribe')
    end
  end
end

shared_examples 'an email with a labels subscriptions link in its footer' do
  it { is_expected.to have_body_text('label subscriptions') }
end
