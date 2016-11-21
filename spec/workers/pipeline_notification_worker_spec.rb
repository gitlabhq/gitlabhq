require 'spec_helper'

describe PipelineNotificationWorker do
  let(:pipeline) do
    create(:ci_pipeline,
           project: project,
           sha: project.commit('master').sha,
           user: pusher,
           status: status)
  end

  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:pusher) { user }
  let(:watcher) { pusher }

  describe '#execute' do
    before do
      reset_delivered_emails!
      pipeline.project.team << [pusher, Gitlab::Access::DEVELOPER]
    end

    context 'when watcher has developer access' do
      before do
        pipeline.project.team << [watcher, Gitlab::Access::DEVELOPER]
      end

      shared_examples 'sending emails' do
        it 'sends emails' do
          perform_enqueued_jobs do
            subject.perform(pipeline.id)
          end

          emails = ActionMailer::Base.deliveries
          actual = emails.flat_map(&:bcc).sort
          expected_receivers = receivers.map(&:email).uniq.sort

          expect(actual).to eq(expected_receivers)
          expect(emails.size).to eq(1)
          expect(emails.last.subject).to include(email_subject)
        end
      end

      context 'with success pipeline' do
        let(:status) { 'success' }
        let(:email_subject) { "Pipeline ##{pipeline.id} has succeeded" }
        let(:receivers) { [pusher, watcher] }

        it_behaves_like 'sending emails'

        context 'with pipeline from someone else' do
          let(:pusher) { create(:user) }
          let(:watcher) { user }

          context 'with success pipeline notification on' do
            before do
              watcher.global_notification_setting.
                update(level: 'custom', success_pipeline: true)
            end

            it_behaves_like 'sending emails'
          end

          context 'with success pipeline notification off' do
            let(:receivers) { [pusher] }

            before do
              watcher.global_notification_setting.
                update(level: 'custom', success_pipeline: false)
            end

            it_behaves_like 'sending emails'
          end
        end

        context 'with failed pipeline' do
          let(:status) { 'failed' }
          let(:email_subject) { "Pipeline ##{pipeline.id} has failed" }

          it_behaves_like 'sending emails'

          context 'with pipeline from someone else' do
            let(:pusher) { create(:user) }
            let(:watcher) { user }

            context 'with failed pipeline notification on' do
              before do
                watcher.global_notification_setting.
                  update(level: 'custom', failed_pipeline: true)
              end

              it_behaves_like 'sending emails'
            end

            context 'with failed pipeline notification off' do
              let(:receivers) { [pusher] }

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

    context 'when watcher has no read_build access' do
      let(:status) { 'failed' }
      let(:email_subject) { "Pipeline ##{pipeline.id} has failed" }
      let(:watcher) { create(:user) }

      before do
        pipeline.project.team << [watcher, Gitlab::Access::GUEST]

        watcher.global_notification_setting.
          update(level: 'custom', failed_pipeline: true)

        perform_enqueued_jobs do
          subject.perform(pipeline.id)
        end
      end

      it 'does not send emails' do
        should_only_email(pusher, kind: :bcc)
      end
    end
  end
end
