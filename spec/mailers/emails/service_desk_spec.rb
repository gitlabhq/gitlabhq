# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::ServiceDesk do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  include EmailHelpers

  include_context 'gitlab email notification'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:email) { 'someone@gitlab.com' }

  let(:template) { double(content: template_content) }

  before_all do
    issue.issue_email_participants.create!(email: email)
  end

  before do
    stub_const('ServiceEmailClass', Class.new(ApplicationMailer))

    ServiceEmailClass.class_eval do
      include GitlabRoutingHelper
      include EmailsHelper
      include Emails::ServiceDesk

      helper GitlabRoutingHelper
      helper EmailsHelper

      # this method is implemented in Notify class, we don't need to test it
      def reply_key
        'test-key'
      end

      # this method is implemented in Notify class, we don't need to test it
      def sender(author_id, params = {})
        author_id
      end

      # this method is implemented in Notify class
      #
      # We do not need to test the Notify method, it is already tested in notify_spec
      def mail_new_thread(issue, options)
        # we need to rewrite this in order to look up templates in the correct directory
        self.class.mailer_name = 'notify'

        # this is needed for default layout
        @unsubscribe_url = 'http://unsubscribe.example.com'

        mail(options)
      end
      alias_method :mail_answer_thread, :mail_new_thread
    end
  end

  shared_examples 'handle template content' do |template_key, attachments_count|
    before do
      expect(Gitlab::Template::ServiceDeskTemplate).to receive(:find)
        .with(template_key, issue.project)
        .and_return(template)
    end

    it 'builds the email correctly' do
      aggregate_failures do
        is_expected.to have_referable_subject(issue, include_project: false, reply: reply_in_subject)
        is_expected.to have_body_text(expected_body)
        expect(subject.attachments.count).to eq(attachments_count.to_i)
        expect(subject.content_type).to include('text/html')
      end
    end
  end

  shared_examples 'read template from repository' do |template_key|
    let(:template_content) { 'custom text' }
    let(:issue) { create(:issue, project: project) }

    before do
      issue.issue_email_participants.create!(email: email)
    end

    context 'when a template is in the repository' do
      let(:project) { create(:project, :custom_repo, files: { ".gitlab/service_desk_templates/#{template_key}.md" => template_content }) }

      it 'uses the text template from the template' do
        is_expected.to have_body_text(template_content)
      end
    end

    context 'when the service_desk_templates directory does not contain correct template' do
      let(:project) { create(:project, :custom_repo, files: { ".gitlab/service_desk_templates/another_file.md" => template_content }) }

      it 'uses the default template' do
        is_expected.to have_body_text(default_text)
      end
    end

    context 'when the service_desk_templates directory does not exist' do
      let(:project) { create(:project, :custom_repo, files: { "other_directory/another_file.md" => template_content }) }

      it 'uses the default template' do
        is_expected.to have_body_text(default_text)
      end
    end

    context 'when the project does not have a repo' do
      let(:project) { create(:project) }

      it 'uses the default template' do
        is_expected.to have_body_text(default_text)
      end
    end
  end

  describe '.service_desk_thank_you_email' do
    let_it_be(:reply_in_subject) { true }
    let_it_be(:default_text) do
      "Thank you for your support request! We are tracking your request as ticket #{issue.to_reference}, and will respond as soon as we can."
    end

    subject { ServiceEmailClass.service_desk_thank_you_email(issue.id) }

    it_behaves_like 'read template from repository', 'thank_you'

    context 'handling template markdown' do
      context 'with a simple text' do
        let(:template_content) { 'thank you, **your new issue** has been created.' }
        let(:expected_body) { 'thank you, <strong>your new issue</strong> has been created.' }

        it_behaves_like 'handle template content', 'thank_you'
      end

      context 'with an issue id and issue path placeholders' do
        let(:template_content) { 'thank you, **your new issue:** %{ISSUE_ID}, path: %{ISSUE_PATH}' }
        let(:expected_body) { "thank you, <strong>your new issue:</strong> ##{issue.iid}, path: #{project.full_path}##{issue.iid}" }

        it_behaves_like 'handle template content', 'thank_you'
      end

      context 'with an issue id placeholder with whitespace' do
        let(:template_content) { 'thank you, **your new issue:** %{  ISSUE_ID}' }
        let(:expected_body) { "thank you, <strong>your new issue:</strong> ##{issue.iid}" }

        it_behaves_like 'handle template content', 'thank_you'
      end

      context 'with unexpected placeholder' do
        let(:template_content) { 'thank you, **your new issue:** %{this is issue}' }
        let(:expected_body) { "thank you, <strong>your new issue:</strong> %{this is issue}" }

        it_behaves_like 'handle template content', 'thank_you'
      end
    end
  end

  describe '.service_desk_new_note_email' do
    let_it_be(:reply_in_subject) { false }
    let_it_be(:note) { create(:note_on_issue, noteable: issue, project: project) }
    let_it_be(:default_text) { note.note }

    subject { ServiceEmailClass.service_desk_new_note_email(issue.id, note.id, email) }

    it_behaves_like 'read template from repository', 'new_note'

    context 'handling template markdown' do
      context 'with a simple text' do
        let(:template_content) { 'thank you, **new note on issue** has been created.' }
        let(:expected_body) { 'thank you, <strong>new note on issue</strong> has been created.' }

        it_behaves_like 'handle template content', 'new_note'
      end

      context 'with an issue id, issue path and note placeholders' do
        let(:template_content) { 'thank you, **new note on issue:** %{ISSUE_ID}, path: %{ISSUE_PATH}: %{NOTE_TEXT}' }
        let(:expected_body) { "thank you, <strong>new note on issue:</strong> ##{issue.iid}, path: #{project.full_path}##{issue.iid}: #{note.note}" }

        it_behaves_like 'handle template content', 'new_note'
      end

      context 'with an issue id placeholder with whitespace' do
        let(:template_content) { 'thank you, **new note on issue:** %{  ISSUE_ID}: %{ NOTE_TEXT  }' }
        let(:expected_body) { "thank you, <strong>new note on issue:</strong> ##{issue.iid}: #{note.note}" }

        it_behaves_like 'handle template content', 'new_note'
      end

      context 'with unexpected placeholder' do
        let(:template_content) { 'thank you, **new note on issue:** %{this is issue}' }
        let(:expected_body) { "thank you, <strong>new note on issue:</strong> %{this is issue}" }

        it_behaves_like 'handle template content', 'new_note'
      end

      context 'with upload link in the note' do
        let_it_be(:secret) { 'e90decf88d8f96fe9e1389afc2e4a91f' }
        let_it_be(:filename) { 'test.jpg' }
        let_it_be(:path) { "#{secret}/#{filename}" }
        let_it_be(:upload_path) { "/uploads/#{path}" }
        let_it_be(:template_content) { 'some text %{ NOTE_TEXT  }' }
        let_it_be(:note) { create(:note_on_issue, noteable: issue, project: project, note: "a new comment with [#{filename}](#{upload_path})") }
        let!(:upload) { create(:upload, :issuable_upload, :with_file, model: note.project, path: path, secret: secret) }

        context 'when total uploads size is more than 10mb' do
          before do
            allow_next_instance_of(FileUploader) do |instance|
              allow(instance).to receive(:size).and_return(10.1.megabytes)
            end
          end

          let_it_be(:expected_body) { %Q(some text a new comment with <a href="#{project.web_url}#{upload_path}" data-canonical-src="#{upload_path}" data-link="true" class="gfm">#{filename}</a>) }

          it_behaves_like 'handle template content', 'new_note'
        end

        context 'when total uploads size is less or equal 10mb' do
          context 'when it has only one upload' do
            before do
              allow_next_instance_of(FileUploader) do |instance|
                allow(instance).to receive(:size).and_return(10.megabytes)
              end
            end

            context 'when upload name is not changed in markdown' do
              let_it_be(:expected_body) { %Q(some text a new comment with <strong>#{filename}</strong>) }

              it_behaves_like 'handle template content', 'new_note', 1
            end

            context 'when upload name is changed in markdown' do
              let_it_be(:upload_name_in_markdown) { 'Custom name' }
              let_it_be(:note) { create(:note_on_issue, noteable: issue, project: project, note: "a new comment with [#{upload_name_in_markdown}](#{upload_path})") }
              let_it_be(:expected_body) { %Q(some text a new comment with <strong>#{upload_name_in_markdown} (#{filename})</strong>) }

              it_behaves_like 'handle template content', 'new_note', 1
            end
          end

          context 'when it has more than one upload' do
            before do
              allow_next_instance_of(FileUploader) do |instance|
                allow(instance).to receive(:size).and_return(5.megabytes)
              end
            end

            let_it_be(:secret_1) { '17817c73e368777e6f743392e334fb8a' }
            let_it_be(:filename_1) { 'test1.jpg' }
            let_it_be(:path_1) { "#{secret_1}/#{filename_1}" }
            let_it_be(:upload_path_1) { "/uploads/#{path_1}" }
            let_it_be(:note) { create(:note_on_issue, noteable: issue, project: project, note: "a new comment with [#{filename}](#{upload_path}) [#{filename_1}](#{upload_path_1})") }

            context 'when all uploads processed correct' do
              let_it_be(:upload_1) { create(:upload, :issuable_upload, :with_file, model: note.project, path: path_1, secret: secret_1) }
              let_it_be(:expected_body) { %Q(some text a new comment with <strong>#{filename}</strong> <strong>#{filename_1}</strong>) }

              it_behaves_like 'handle template content', 'new_note', 2
            end

            context 'when not all uploads processed correct' do
              let_it_be(:expected_body) { %Q(some text a new comment with <strong>#{filename}</strong> <a href="#{project.web_url}#{upload_path_1}" data-canonical-src="#{upload_path_1}" data-link="true" class="gfm">#{filename_1}</a>) }

              it_behaves_like 'handle template content', 'new_note', 1
            end
          end
        end

        context 'when UploaderFinder is raising error' do
          before do
            allow_next_instance_of(UploaderFinder) do |instance|
              allow(instance).to receive(:execute).and_raise(StandardError)
            end
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(StandardError, project_id: note.project_id)
          end

          let_it_be(:expected_body) { %Q(some text a new comment with <a href="#{project.web_url}#{upload_path}" data-canonical-src="#{upload_path}" data-link="true" class="gfm">#{filename}</a>) }

          it_behaves_like 'handle template content', 'new_note'
        end

        context 'when FileUploader is raising error' do
          before do
            allow_next_instance_of(FileUploader) do |instance|
              allow(instance).to receive(:read).and_raise(StandardError)
            end
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(StandardError, project_id: note.project_id)
          end

          let_it_be(:expected_body) { %Q(some text a new comment with <a href="#{project.web_url}#{upload_path}" data-canonical-src="#{upload_path}" data-link="true" class="gfm">#{filename}</a>) }

          it_behaves_like 'handle template content', 'new_note'
        end
      end

      context 'with all-user reference in a an external author comment' do
        let_it_be(:note) { create(:note_on_issue, noteable: issue, project: project, note: "Hey @all, just a ping", author: User.support_bot) }

        let(:template_content) { 'some text %{ NOTE_TEXT  }' }
        let(:expected_body) { 'Hey , just a ping' }

        it_behaves_like 'handle template content', 'new_note'
      end
    end
  end
end
