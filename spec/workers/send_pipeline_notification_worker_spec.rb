require 'spec_helper'

describe SendPipelineNotificationWorker, services: true do
  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit('master').sha,
           user: user,
           status: status)
  end

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:pusher) { user }
  let(:watcher) { pusher }

  describe '#execute' do
    before do
      reset_delivered_emails!
      pipeline.project.team << [watcher, Gitlab::Access::DEVELOPER]
    end

    shared_examples 'sending emails' do
      it 'sends emails' do
        perform_enqueued_jobs do
          subject.perform(pipeline.id)
        end

        expected_receivers = [pusher, watcher].uniq.sort_by(&:email)
        actual = ActionMailer::Base.deliveries.sort_by(&:to)

        expect(expected_receivers.size).to eq(actual.size)

        actual.zip(expected_receivers).each do |(email, receiver)|
          expect(email.subject).to include(email_subject)
          expect(email.to).to eq([receiver.email])
        end
      end
    end

    context 'with success pipeline' do
      let(:status) { 'success' }
      let(:email_subject) { "Pipeline ##{pipeline.id} has succeeded" }

      it_behaves_like 'sending emails'

      context 'with pipeline from someone else' do
        let(:pusher) { create(:user) }

        context 'with success pipeline notification on' do
          let(:watcher) { user }

          before do
            watcher.global_notification_setting.
              update(level: 'custom', success_pipeline: true)
          end

          it_behaves_like 'sending emails'
        end

        context 'with success pipeline notification off' do
          before do
            watcher.global_notification_setting.
              update(level: 'custom', success_pipeline: false)
          end

          it_behaves_like 'sending emails'
        end
      end
    end

    context 'with failed pipeline' do
      let(:status) { 'failed' }
      let(:email_subject) { "Pipeline ##{pipeline.id} has failed" }

      it_behaves_like 'sending emails'

      context 'with pipeline from someone else' do
        let(:pusher) { create(:user) }

        context 'with failed pipeline notification on' do
          let(:watcher) { user }

          before do
            watcher.global_notification_setting.
              update(level: 'custom', failed_pipeline: true)
          end

          it_behaves_like 'sending emails'
        end

        context 'with failed pipeline notification off' do
          before do
            watcher.global_notification_setting.
              update(level: 'custom', failed_pipeline: false)
          end

          it_behaves_like 'sending emails'
        end
      end
    end
  end
end
