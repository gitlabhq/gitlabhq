# frozen_string_literal: true

require 'spec_helper'

describe PipelinesEmailService, :mailer do
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
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  describe '#test_data' do
    let(:build)   { create(:ci_build) }
    let(:project) { build.project }
    let(:user)    { create(:user) }

    before do
      project.add_developer(user)
    end

    it 'builds test data' do
      data = subject.test_data(project, user)

      expect(data[:object_kind]).to eq('pipeline')
    end
  end

  shared_examples 'sending email' do
    before do
      subject.recipients = recipients

      perform_enqueued_jobs do
        run
      end
    end

    it 'sends email' do
      emails = receivers.map { |r| double(notification_email: r) }

      should_only_email(*emails, kind: :bcc)
    end
  end

  shared_examples 'not sending email' do
    before do
      subject.recipients = recipients

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
        pipeline.update(status: 'success')
      end

      it_behaves_like 'sending email'
    end

    context 'when pipeline is failed and on a non-default branch' do
      before do
        data[:object_attributes][:ref] = 'not-the-default-branch'
        pipeline.update(ref: 'not-the-default-branch')
      end

      context 'with notify_only_default branch on' do
        before do
          subject.notify_only_default_branch = true
        end

        it_behaves_like 'sending email'
      end

      context 'with notify_only_default_branch off' do
        it_behaves_like 'sending email'
      end
    end
  end

  describe '#execute' do
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
          pipeline.update(status: 'success')
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
            pipeline.update(status: 'success')
          end

          it_behaves_like 'not sending email'
        end
      end

      context 'with notify_only_default_branch off' do
        context 'with default branch' do
          it_behaves_like 'sending email'
        end

        context 'with non default branch' do
          before do
            data[:object_attributes][:ref] = 'not-the-default-branch'
            pipeline.update(ref: 'not-the-default-branch')
          end

          it_behaves_like 'sending email'
        end
      end

      context 'with notify_only_default_branch on' do
        before do
          subject.notify_only_default_branch = true
        end

        context 'with default branch' do
          it_behaves_like 'sending email'
        end

        context 'with non default branch' do
          before do
            data[:object_attributes][:ref] = 'not-the-default-branch'
            pipeline.update(ref: 'not-the-default-branch')
          end

          it_behaves_like 'not sending email'
        end
      end
    end

    context 'with empty recipients list' do
      let(:recipients) { ' ,, ' }

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update(status: 'failed')
        end

        it_behaves_like 'not sending email'
      end
    end

    context 'with recipients list separating with newlines' do
      let(:recipients) { "\ntest@gitlab.com,  \r\nexample@gitlab.com" }
      let(:receivers) { %w[test@gitlab.com example@gitlab.com] }

      context 'with failed pipeline' do
        before do
          data[:object_attributes][:status] = 'failed'
          pipeline.update(status: 'failed')
        end

        it_behaves_like 'sending email'
      end
    end
  end
end
