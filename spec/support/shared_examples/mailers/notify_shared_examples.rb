# frozen_string_literal: true

RSpec.shared_examples 'a multiple recipients email' do
  it 'is sent to the given recipient' do
    is_expected.to deliver_to recipient.notification_email_or_default
  end
end

RSpec.shared_examples 'an email sent from GitLab' do
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

RSpec.shared_examples 'an email sent to a user' do
  it 'is sent to user\'s global notification email address' do
    expect(subject).to deliver_to(recipient.notification_email_or_default)
  end

  context 'with group notification email' do
    it 'is sent to user\'s group notification email' do
      group_notification_email = 'user+group@example.com'

      create(:email, :confirmed, user: recipient, email: group_notification_email)
      create(:notification_setting, user: recipient, source: group, notification_email: group_notification_email)

      expect(subject).to deliver_to(group_notification_email)
    end
  end
end

RSpec.shared_examples 'an email with suffix' do
  before do
    stub_config_setting(email_subject_suffix: 'Suffix')
  end

  it 'adds a correct suffix to subject' do
    expect(subject.subject).to end_with('| Suffix')
  end
end

RSpec.shared_examples 'an email that contains a header with author username' do
  it 'has X-GitLab-Author header containing author\'s username' do
    is_expected.to have_header 'X-GitLab-Author', user.username
  end
end

RSpec.shared_examples 'an email with X-GitLab headers containing IDs' do
  it 'has X-GitLab-*-ID header' do
    is_expected.to have_header "X-GitLab-#{model.class.name}-ID", model.id.to_s
  end

  it 'has X-GitLab-*-IID header if model has iid defined' do
    if model.respond_to?(:iid)
      is_expected.to have_header "X-GitLab-#{model.class.name}-IID", model.iid.to_s
    else
      expect(subject.header["X-GitLab-#{model.class.name}-IID"]).to eq nil
    end
  end

  it 'has X-GitLab-*-State header if model has state defined' do
    if model.respond_to?(:state)
      is_expected.to have_header "X-GitLab-#{model.class.name}-State", model.state.to_s
    else
      expect(subject.header["X-GitLab-#{model.class.name}-State"]).to eq nil
    end
  end
end

RSpec.shared_examples 'an email with X-GitLab headers containing project details' do
  it 'has X-GitLab-Project headers' do
    aggregate_failures do
      full_path_as_domain = "#{project.path}.#{project.namespace.path}"
      is_expected.to have_header('X-GitLab-Project', /#{project.name}/)
      is_expected.to have_header('X-GitLab-Project-Id', /#{project.id}/)
      is_expected.to have_header('X-GitLab-Project-Path', /#{project.full_path}/)
      is_expected.to have_header('List-Id', "#{project.full_path} <#{project.id}.#{full_path_as_domain}.#{Gitlab.config.gitlab.host}>")
    end
  end
end

RSpec.shared_examples 'a new thread email with reply-by-email enabled' do
  it 'has the characteristics of a threaded email' do
    host = Gitlab.config.gitlab.host
    route_key = "#{model.class.model_name.singular_route_key}_#{model.id}"

    aggregate_failures do
      is_expected.to have_header('Message-ID', "<#{route_key}@#{host}>")
      is_expected.to have_header('References', /\A<reply-.*@#{host}>\Z/)
    end
  end
end

RSpec.shared_examples 'a thread answer email with reply-by-email enabled' do |group_level = false|
  include_examples 'an email with X-GitLab headers containing project details' unless group_level
  include_examples 'an email with X-GitLab headers containing IDs'

  it 'has the characteristics of a threaded reply' do
    host = Gitlab.config.gitlab.host
    route_key = "#{model.class.model_name.singular_route_key}_#{model.id}"

    aggregate_failures do
      is_expected.to have_header('Message-ID', /\A<.*@#{host}>\Z/)
      is_expected.to have_header('In-Reply-To', "<#{route_key}@#{host}>")
      is_expected.to have_header('References', /\A<reply-.*@#{host}> <#{route_key}@#{host}>\Z/)
      is_expected.to have_subject(/^Re: /)
    end
  end
end

RSpec.shared_examples 'an email starting a new thread with reply-by-email enabled' do |group_level = false|
  include_examples 'an email with X-GitLab headers containing project details' unless group_level
  include_examples 'an email with X-GitLab headers containing IDs'
  include_examples 'a new thread email with reply-by-email enabled'

  it 'includes "Reply to this email directly or <View it on GitLab>"' do
    expect(subject.default_part.body).to include(%(Reply to this email directly or <a href="#{Gitlab::UrlBuilder.build(model)}">view it on GitLab</a>.))
  end

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

RSpec.shared_examples 'an answer to an existing thread with reply-by-email enabled' do |group_level = false|
  include_examples 'a thread answer email with reply-by-email enabled', group_level

  context 'when reply-by-email is enabled with incoming address with %{key}' do
    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply+(.*)@#{Gitlab.config.gitlab.host}>\Z/
    end
  end

  context 'when reply-by-email is enabled with incoming address without %{key}' do
    include_context 'reply-by-email is enabled with incoming address without %{key}'
    include_examples 'a thread answer email with reply-by-email enabled', group_level

    it 'has a Reply-To header' do
      is_expected.to have_header 'Reply-To', /<reply@#{Gitlab.config.gitlab.host}>\Z/
    end
  end
end

RSpec.shared_examples 'it should have Gmail Actions links' do
  it do
    aggregate_failures do
      is_expected.to have_body_text('<script type="application/ld+json">')
      is_expected.to have_body_text('ViewAction')
    end
  end
end

RSpec.shared_examples 'it should not have Gmail Actions links' do
  it do
    aggregate_failures do
      is_expected.not_to have_body_text('<script type="application/ld+json">')
      is_expected.not_to have_body_text('ViewAction')
    end
  end
end

RSpec.shared_examples 'it should show Gmail Actions Join now link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('Join now') }
end

RSpec.shared_examples 'it should show Gmail Actions View Issue link' do |group_level = false|
  it_behaves_like 'it should have Gmail Actions links'

  it 'show the correct view action text' do
    if group_level
      is_expected.to have_body_text('View Work item')
    else
      is_expected.to have_body_text('View Issue')
    end
  end
end

RSpec.shared_examples 'it should show Gmail Actions View Merge request link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('View Merge request') }
end

RSpec.shared_examples 'it should show Gmail Actions View Commit link' do
  it_behaves_like 'it should have Gmail Actions links'

  it { is_expected.to have_body_text('View Commit') }
end

RSpec.shared_examples 'an unsubscribeable thread' do
  it_behaves_like 'an unsubscribeable thread with incoming address without %{key}'

  it 'has a List-Unsubscribe header in the correct format, List-Unsubscribe-Post header, and a body link' do
    aggregate_failures do
      is_expected.to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.to have_header('List-Unsubscribe', /mailto/)
      is_expected.to have_header('List-Unsubscribe', /^<.+,.+>$/)
      # Ensure force parameter is not present because some firewall scans access header links
      # and so would automatically unsubscribe participants.
      is_expected.not_to have_header('List-Unsubscribe', /force=true/)
      is_expected.to have_header('List-Unsubscribe-Post', 'List-Unsubscribe=One-Click')
      is_expected.to have_body_text('unsubscribe')
    end
  end
end

RSpec.shared_examples 'an unsubscribeable thread with incoming address without %{key}' do
  include_context 'reply-by-email is enabled with incoming address without %{key}'

  it 'has a List-Unsubscribe header in the correct format, List-Unsubscribe-Post header, and a body link' do
    aggregate_failures do
      is_expected.to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.not_to have_header('List-Unsubscribe', /mailto/)
      is_expected.to have_header('List-Unsubscribe', /^<[^,]+>$/)
      is_expected.to have_header('List-Unsubscribe-Post', 'List-Unsubscribe=One-Click')
      is_expected.to have_body_text('unsubscribe')
    end
  end
end

RSpec.shared_examples 'a user cannot unsubscribe through footer link' do
  it 'does not have a List-Unsubscribe header, List-Unsubscribe-Post header or a body link' do
    aggregate_failures do
      is_expected.not_to have_header('List-Unsubscribe', /unsubscribe/)
      is_expected.not_to have_header('List-Unsubscribe-Post', 'List-Unsubscribe=One-Click')
      is_expected.not_to have_body_text('unsubscribe')
    end
  end
end

RSpec.shared_examples 'an email with a labels subscriptions link in its footer' do |group_level = false|
  it { is_expected.to have_body_text('label subscriptions') }

  it 'has the correct labels URL' do
    if group_level
      is_expected.to have_body_text(%(href="#{group_labels_url(group, subscribed: true)}"))
    else
      is_expected.to have_body_text(%(href="#{project_labels_url(project, subscribed: true)}"))
    end
  end
end

RSpec.shared_examples 'a note email' do
  it_behaves_like 'it should have Gmail Actions links'

  it 'is sent to the given recipient as the author' do
    sender = subject.header[:from].addrs[0]

    aggregate_failures do
      expect(sender.display_name).to eq("#{note_author.name} (@#{note_author.username})")
      expect(sender.address).to eq(gitlab_sender)
      expect(subject).to deliver_to(recipient.notification_email_or_default)
    end
  end

  it 'contains the message from the note' do
    is_expected.to have_body_text note.note
  end

  it 'contains a link to note author' do
    is_expected.to have_body_text note.author_name
  end
end

RSpec.shared_examples 'appearance header and footer enabled' do
  it "contains header and footer" do
    create :appearance, header_message: "Foo", footer_message: "Bar", email_header_and_footer_enabled: true

    aggregate_failures do
      expect(subject.html_part).to have_body_text("<div class=\"header-message\" style=\"\"><p>Foo</p></div>")
      expect(subject.html_part).to have_body_text("<div class=\"footer-message\" style=\"\"><p>Bar</p></div>")

      expect(subject.text_part).to have_body_text(/^Foo/)
      expect(subject.text_part).to have_body_text(/Bar$/)
    end
  end
end

RSpec.shared_examples 'appearance header and footer not enabled' do
  it "does not contain header and footer" do
    create :appearance, header_message: "Foo", footer_message: "Bar", email_header_and_footer_enabled: false

    aggregate_failures do
      expect(subject.html_part).not_to have_body_text("<div class=\"header-message\" style=\"\"><p>Foo</p></div>")
      expect(subject.html_part).not_to have_body_text("<div class=\"footer-message\" style=\"\"><p>Bar</p></div>")

      expect(subject.text_part).not_to have_body_text(/^Foo/)
      expect(subject.text_part).not_to have_body_text(/Bar$/)
    end
  end
end

RSpec.shared_examples 'no email is sent' do
  it 'does not send an email' do
    expect(subject.message).to be_a_kind_of(ActionMailer::Base::NullMail)
  end
end

RSpec.shared_examples 'a mail with default delivery method' do
  it 'uses mailer default delivery method' do
    expect(subject.delivery_method).to be_a ActionMailer::Base.delivery_methods[described_class.delivery_method]
  end
end

RSpec.shared_examples 'does not render a manage notifications link' do
  it do
    aggregate_failures do
      expect(subject).not_to have_body_text("Manage all notifications")
      expect(subject).not_to have_body_text(profile_notifications_url)
    end
  end
end

RSpec.shared_examples 'email with default notification reason' do
  it do
    is_expected.to have_body_text("You're receiving this email because of your account")
    is_expected.to have_plain_text_content("You're receiving this email because of your account")
  end
end

RSpec.shared_examples 'email with link to issue' do
  it do
    is_expected.to have_body_text(%(<a href="#{Gitlab::UrlBuilder.build(issue)}">view it on GitLab</a>))
    is_expected.to have_plain_text_content("view it on GitLab: #{Gitlab::UrlBuilder.build(issue)}")
  end
end
