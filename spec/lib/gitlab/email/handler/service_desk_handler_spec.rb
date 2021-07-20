# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::ServiceDeskHandler do
  include_context :email_shared_context

  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { email_fixture('emails/service_desk.eml') }
  let_it_be(:group) { create(:group, :private, name: "email") }

  let(:expected_description) do
    "Service desk stuff!\n\n```\na = b\n```\n\n`/label ~label1`\n`/assign @user1`\n`/close`\n![image](uploads/image.png)"
  end

  context 'service desk is enabled for the project' do
    let_it_be(:project) { create(:project, :repository, :private, group: group, path: 'test', service_desk_enabled: true) }

    before do
      allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
    end

    shared_examples 'a new issue request' do
      before do
        setup_attachment
      end

      it 'creates a new issue' do
        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.author).to eql(User.support_bot)
        expect(new_issue.confidential?).to be true
        expect(new_issue.all_references.all).to be_empty
        expect(new_issue.title).to eq("The message subject! @all")
        expect(new_issue.description).to eq(expected_description.strip)
      end

      it 'creates an issue_email_participant' do
        receiver.execute
        new_issue = Issue.last

        expect(new_issue.issue_email_participants.first.email).to eq("jake@adventuretime.ooo")
      end

      it 'sends thank you email' do
        expect { receiver.execute }.to have_enqueued_job.on_queue('mailers')
      end

      it 'adds metric events for incoming and reply emails' do
        metric_transaction = double('Gitlab::Metrics::WebTransaction', increment: true, observe: true)
        allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
        expect(metric_transaction).to receive(:add_event).with(:receive_email_service_desk, { handler: 'Gitlab::Email::Handler::ServiceDeskHandler' })
        expect(metric_transaction).to receive(:add_event).with(:service_desk_thank_you_email)

        receiver.execute
      end
    end

    context 'when everything is fine' do
      it_behaves_like 'a new issue request'

      context 'with legacy incoming email address' do
        let(:email_raw) { fixture_file('emails/service_desk_legacy.eml') }

        it_behaves_like 'a new issue request'
      end

      context 'when using issue templates' do
        let_it_be(:user) { create(:user) }

        before do
          setup_attachment
        end

        context 'and template is present' do
          let_it_be(:settings) { create(:service_desk_setting, project: project) }

          def set_template_file(file_name, content)
            file_path = ".gitlab/issue_templates/#{file_name}.md"
            project.repository.create_file(user, file_path, content, message: 'message', branch_name: 'master')
            settings.update!(issue_template_key: file_name)
          end

          it 'appends template text to issue description' do
            set_template_file('service_desk', 'text from template')

            receiver.execute

            issue_description = Issue.last.description
            expect(issue_description).to include(expected_description)
            expect(issue_description.lines.last).to eq('text from template')
          end

          context 'when quick actions are present' do
            let(:label) { create(:label, project: project, title: 'label1') }
            let(:milestone) { create(:milestone, project: project) }

            it 'applies quick action commands present on templates' do
              file_content = %(Text from template \n/label ~#{label.title} \n/milestone %"#{milestone.name}"")
              set_template_file('with_slash_commands', file_content)

              receiver.execute

              issue = Issue.last
              expect(issue.description).to include('Text from template')
              expect(issue.label_ids).to include(label.id)
              expect(issue.milestone).to eq(milestone)
            end

            it 'applies group labels using quick actions' do
              group_label = create(:group_label, group: project.group, title: 'label2')
              file_content = %(Text from template \n/label ~#{group_label.title}"")
              set_template_file('with_group_labels', file_content)

              receiver.execute

              issue = Issue.last
              expect(issue.description).to include('Text from template')
              expect(issue.label_ids).to include(group_label.id)
            end

            it 'redacts quick actions present on user email body' do
              set_template_file('service_desk1', 'text from template')

              receiver.execute

              issue = Issue.last
              expect(issue).to be_opened
              expect(issue.description).to include('`/label ~label1`')
              expect(issue.description).to include('`/assign @user1`')
              expect(issue.description).to include('`/close`')
              expect(issue.assignees).to be_empty
              expect(issue.milestone).to be_nil
            end
          end
        end

        context 'and template cannot be found' do
          before do
            service = ServiceDeskSetting.new(project_id: project.id, issue_template_key: 'unknown')
            service.save!(validate: false)
          end

          it 'does not append template text to issue description' do
            receiver.execute

            new_issue = Issue.last

            expect(new_issue.description).to eq(expected_description.strip)
          end

          it 'creates support bot note on issue' do
            receiver.execute

            note = Note.last

            expect(note.note).to include("WARNING: The template file unknown.md used for service desk issues is empty or could not be found.")
            expect(note.author).to eq(User.support_bot)
          end

          it 'does not send warning note email' do
            ActionMailer::Base.deliveries = []

            perform_enqueued_jobs do
              expect { receiver.execute }.to change { ActionMailer::Base.deliveries.size }.by(1)
            end

            # Only sends created issue email
            expect(ActionMailer::Base.deliveries.last.text_part.body).to include("Thank you for your support request!")
          end
        end
      end

      context 'when using service desk key' do
        let_it_be(:service_desk_key) { 'mykey' }

        let(:email_raw) { service_desk_fixture('emails/service_desk_custom_address.eml') }
        let(:receiver) { Gitlab::Email::ServiceDeskReceiver.new(email_raw) }

        before do
          stub_service_desk_email_setting(enabled: true, address: 'support+%{key}@example.com')
        end

        before_all do
          create(:service_desk_setting, project: project, project_key: service_desk_key)
        end

        it_behaves_like 'a new issue request'

        context 'when there is no project with the key' do
          let(:email_raw) { service_desk_fixture('emails/service_desk_custom_address.eml', key: 'some_key') }

          it 'bounces the email' do
            expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
          end
        end

        context 'when the project slug does not match' do
          let(:email_raw) { service_desk_fixture('emails/service_desk_custom_address.eml', slug: 'some-slug') }

          it 'bounces the email' do
            expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
          end
        end

        context 'when there are multiple projects with same key' do
          let_it_be(:project_with_same_key) { create(:project, group: group, service_desk_enabled: true) }

          let(:email_raw) { service_desk_fixture('emails/service_desk_custom_address.eml', slug: project_with_same_key.full_path_slug.to_s) }

          before do
            create(:service_desk_setting, project: project_with_same_key, project_key: service_desk_key)
          end

          it 'process email for project with matching slug' do
            expect { receiver.execute }.to change { Issue.count }.by(1)
            expect(Issue.last.project).to eq(project_with_same_key)
          end
        end
      end
    end

    describe '#can_handle?' do
      let(:mail) { Mail::Message.new(email_raw) }

      it 'handles the new email key format' do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-#{project.project_id}-issue-")

        expect(handler.instance_variable_get(:@project_id).to_i).to eq project.project_id
        expect(handler.can_handle?).to be_truthy
      end

      it 'handles the legacy email key format' do
        handler = described_class.new(mail, "h5bp/html5-boilerplate")

        expect(handler.instance_variable_get(:@project_path)).to eq 'h5bp/html5-boilerplate'
        expect(handler.can_handle?).to be_truthy
      end

      it "doesn't handle invalid email key" do
        handler = described_class.new(mail, "h5bp-html5-boilerplate-invalid")

        expect(handler.can_handle?).to be_falsey
      end
    end

    context 'when there is no from address' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:from_address).and_return(nil)
        end
      end

      it "creates a new issue" do
        expect { receiver.execute }.to change { Issue.count }.by(1)
      end

      it 'does not send thank you email' do
        expect { receiver.execute }.not_to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'when there is a sender address and a from address' do
      let(:email_raw) { email_fixture('emails/service_desk_sender_and_from.eml') }

      it 'prefers the from address' do
        setup_attachment

        expect { receiver.execute }.to change { Issue.count }.by(1)

        new_issue = Issue.last

        expect(new_issue.external_author).to eq('finn@adventuretime.ooo')
      end
    end

    context 'when service desk is not enabled for project' do
      before do
        allow(Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
      end

      it 'does not create an issue' do
        expect { receiver.execute rescue nil }.not_to change { Issue.count }
      end

      it 'does not send thank you email' do
        expect { receiver.execute rescue nil }.not_to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'when the email is forwarded through an alias' do
      let(:email_raw) { email_fixture('emails/service_desk_forwarded.eml') }

      it_behaves_like 'a new issue request'
    end

    context 'when the email is forwarded' do
      let(:email_raw) { email_fixture('emails/service_desk_forwarded_new_issue.eml') }

      it_behaves_like 'a new issue request' do
        let(:expected_description) do
          <<~EOF
            Service desk stuff!

            ---------- Forwarded message ---------
            From: Jake the Dog <jake@adventuretime.ooo>
            To: <jake@adventuretime.ooo>


            forwarded content

            ![image](uploads/image.png)
          EOF
        end
      end
    end
  end

  context 'service desk is disabled for the project' do
    let(:group) { create(:group)}
    let(:project) { create(:project, :public, group: group, path: 'test', service_desk_enabled: false) }

    it 'bounces the email' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::ProcessingError)
    end

    it "doesn't create an issue" do
      expect { receiver.execute rescue nil }.not_to change { Issue.count }
    end
  end

  def email_fixture(path)
    fixture_file(path).gsub('project_id', project.project_id.to_s)
  end

  def service_desk_fixture(path, slug: nil, key: 'mykey')
    slug ||= project.full_path_slug.to_s
    fixture_file(path).gsub('project_slug', slug).gsub('project_key', key)
  end
end
