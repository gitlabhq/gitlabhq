# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::PipelinesEmail, :mailer do
  let(:pipeline) do
    create(:ci_pipeline, :failed,
      project: project,
      sha: project.commit('master').sha,
      ref: project.default_branch
    )
  end

  let(:project) { create(:project, :repository) }
  let(:recipients) { 'test@gitlab.com' }
  let(:receivers) { [recipients] }

  let(:data) do
    Gitlab::DataBuilder::Pipeline.build(pipeline)
  end

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

  shared_examples 'sending email' do |branches_to_be_notified: nil|
    before do
      subject.recipients = recipients
      subject.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified

      perform_enqueued_jobs do
        run
      end
    end

    it 'sends email' do
      emails = receivers.map { |r| double(notification_email: r) }

      should_only_email(*emails, kind: :bcc)
    end
  end

  shared_examples 'not sending email' do |branches_to_be_notified: nil|
    before do
      subject.recipients = recipients
      subject.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified

      perform_enqueued_jobs do
        run
      end
    end

    it 'does not send email' do
      should_not_email_anyone
    end
  end

  describe '#test' do
    def run
      subject.test(data)
    end

    context 'when pipeline is failed and on default branch' do
      it_behaves_like 'sending email'
    end

    context 'when pipeline is succeeded' do
      before do
        data[:object_attributes][:status] = 'success'
        pipeline.update!(status: 'success')
      end

      it_behaves_like 'sending email'
    end

    context 'when the pipeline failed' do
      context 'on default branch' do
        before do
          data[:object_attributes][:ref] = project.default_branch
          pipeline.update!(ref: project.default_branch)
        end

        context 'notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'notifications are enabled only for default and protected branches ' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'notifications are enabled only for all branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end
      end

      context 'on a protected branch' do
        before do
          create(:protected_branch, project: project, name: 'a-protected-branch')
          data[:object_attributes][:ref] = 'a-protected-branch'
          pipeline.update!(ref: 'a-protected-branch')
        end

        context 'notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'notifications are enabled only for default and protected branches ' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'notifications are enabled only for all branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end
      end

      context 'on a neither protected nor default branch' do
        before do
          data[:object_attributes][:ref] = 'a-random-branch'
          pipeline.update!(ref: 'a-random-branch')
        end

        context 'notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'notifications are enabled only for default and protected branches ' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'notifications are enabled only for all branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end
      end
    end
  end

  describe '#execute' do
    before do
      subject.project = project
    end

    def run
      subject.execute(data)
    end

    context 'with recipients' do
      context 'with failed pipeline' do
        it_behaves_like 'sending email'
      end

      context 'with succeeded pipeline' do
        before do
          data[:object_attributes][:status] = 'success'
          pipeline.update!(status: 'success')
        end

        it_behaves_like 'not sending email'
      end

      context 'with notify_only_broken_pipelines on' do
        before do
          subject.notify_only_broken_pipelines = true
        end

        context 'with failed pipeline' do
          it_behaves_like 'sending email'
        end

        context 'with succeeded pipeline' do
          before do
            data[:object_attributes][:status] = 'success'
            pipeline.update!(status: 'success')
          end

          it_behaves_like 'not sending email'
        end
      end

      context 'when the pipeline failed' do
        context 'on default branch' do
          before do
            data[:object_attributes][:ref] = project.default_branch
            pipeline.update!(ref: project.default_branch)
          end

          context 'notifications are enabled only for default branch' do
            it_behaves_like 'sending email', branches_to_be_notified: "default"
          end

          context 'notifications are enabled only for protected branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "protected"
          end

          context 'notifications are enabled only for default and protected branches ' do
            it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'notifications are enabled only for all branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "all"
          end
        end

        context 'on a protected branch' do
          before do
            create(:protected_branch, project: project, name: 'a-protected-branch')
            data[:object_attributes][:ref] = 'a-protected-branch'
            pipeline.update!(ref: 'a-protected-branch')
          end

          context 'notifications are enabled only for default branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default"
          end

          context 'notifications are enabled only for protected branch' do
            it_behaves_like 'sending email', branches_to_be_notified: "protected"
          end

          context 'notifications are enabled only for default and protected branches ' do
            it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'notifications are enabled only for all branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "all"
          end
        end

        context 'on a neither protected nor default branch' do
          before do
            data[:object_attributes][:ref] = 'a-random-branch'
            pipeline.update!(ref: 'a-random-branch')
          end

          context 'notifications are enabled only for default branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default"
          end

          context 'notifications are enabled only for protected branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "protected"
          end

          context 'notifications are enabled only for default and protected branches ' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'notifications are enabled only for all branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "all"
          end
        end
      end
    end

    context 'with empty recipients list' do
      let(:recipients) { ' ,, ' }

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update!(status: 'failed')
        end

        it_behaves_like 'not sending email'
      end
    end

    context 'with recipients list separating with newlines' do
      let(:recipients) { "\ntest@gitlab.com,  \r\nexample@gitlab.com\rother@gitlab.com" }
      let(:receivers) { %w[test@gitlab.com example@gitlab.com other@gitlab.com] }

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update!(status: 'failed')
        end

        it_behaves_like 'sending email'
      end
    end
  end
end
