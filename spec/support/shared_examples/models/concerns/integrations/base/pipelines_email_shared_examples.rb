# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::PipelinesEmail do
  let(:pipeline) do
    create(:ci_pipeline, :failed,
      project: project,
      sha: project.commit('master').sha,
      ref: project.default_branch
    )
  end

  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:recipients) { 'test@gitlab.com' }
  let(:receivers) { [recipients] }

  let(:data) do
    Gitlab::DataBuilder::Pipeline.build(pipeline)
  end

  # The outbound rate limit ships flag-off, so the existing send specs assert
  # the pre-limit behaviour. The dedicated 'with rate limiting' context stubs
  # the limiter directly rather than relying on this flag state.
  #
  before do
    stub_feature_flags(pipelines_email_email_rate_limit: false)
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

    describe 'validates number of recipients' do
      before do
        stub_const("Integrations::Base::PipelinesEmail::RECIPIENTS_LIMIT", 2)
      end

      subject(:integration) do
        integration = described_class.new(recipients: recipients, active: true)
        integration.project = project unless integration.instance?
        integration
      end

      context 'with valid number of recipients' do
        let(:recipients) { 'foo@bar.com, , ' }

        it 'does not count empty emails' do
          is_expected.to be_valid
        end
      end

      context 'with invalid number of recipients' do
        let(:recipients) { 'foo@bar.com bar@foo.com bob@gitlab.com' }

        it { is_expected.not_to be_valid }

        it 'adds an error message' do
          integration.valid?

          expect(integration.errors).to contain_exactly('Recipients can\'t exceed 2')
        end

        context 'when integration is not active' do
          before do
            integration.active = false
          end

          it { is_expected.to be_valid }
        end
      end
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

    # rubocop:disable RSpec/NoExpectationExample -- expectation is present
    it 'sends email' do
      emails = receivers.map do |r|
        double(notification_email_or_default: r, username: r, id: r) # rubocop:disable RSpec/VerifiedDoubles -- legacy use
      end

      should_only_email(*emails)
    end
    # rubocop:enable RSpec/NoExpectationExample
  end

  shared_examples 'not sending email' do |branches_to_be_notified: nil|
    before do
      subject.recipients = recipients
      subject.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified

      perform_enqueued_jobs do
        run
      end
    end

    # rubocop:disable RSpec/NoExpectationExample -- expectation is present
    it 'does not send email' do
      should_not_email_anyone
    end
    # rubocop:enable RSpec/NoExpectationExample
  end

  # aliases for pipeline notification integration shared examples
  shared_examples 'triggered PipelinesEmail integration' do
    it_behaves_like 'sending email'
  end

  shared_examples 'untriggered PipelinesEmail integration' do
    it_behaves_like 'not sending email'
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

        context 'when notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'when notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'when notifications are enabled only for default and protected branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'when notifications are enabled only for all branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end
      end

      context 'on a protected branch' do
        before do
          create(:protected_branch, project: project, name: 'a-protected-branch')
          data[:object_attributes][:ref] = 'a-protected-branch'
          pipeline.update!(ref: 'a-protected-branch')
        end

        context 'when notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'when notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'when notifications are enabled only for default and protected branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'when notifications are enabled only for all branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "all"
        end
      end

      context 'on a neither protected nor default branch' do
        before do
          data[:object_attributes][:ref] = 'a-random-branch'
          pipeline.update!(ref: 'a-random-branch')
        end

        context 'when notifications are enabled only for default branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "default"
        end

        context 'when notifications are enabled only for protected branch' do
          it_behaves_like 'sending email', branches_to_be_notified: "protected"
        end

        context 'when notifications are enabled only for default and protected branches' do
          it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
        end

        context 'when notifications are enabled only for all branches' do
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

      context 'with pipeline and ref status' do
        it_behaves_like 'pipeline notification integration', 'PipelinesEmail'
      end

      context 'when the pipeline failed' do
        context 'on default branch' do
          it_behaves_like 'sending email'

          context 'when notifications are enabled only for default branch' do
            it_behaves_like 'sending email', branches_to_be_notified: "default"
          end

          context 'when notifications are enabled only for protected branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "protected"
          end

          context 'when notifications are enabled only for default and protected branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'when notifications are enabled only for all branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "all"
          end
        end

        context 'on a protected branch' do
          before do
            create(:protected_branch, project: project, name: 'a-protected-branch')
            data[:object_attributes][:ref] = 'a-protected-branch'
            pipeline.update!(ref: 'a-protected-branch')
          end

          context 'when notifications are enabled only for default branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default"
          end

          context 'when notifications are enabled only for protected branch' do
            it_behaves_like 'sending email', branches_to_be_notified: "protected"
          end

          context 'when notifications are enabled only for default and protected branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'when notifications are enabled only for all branches' do
            it_behaves_like 'sending email', branches_to_be_notified: "all"
          end
        end

        context 'on a neither protected nor default branch' do
          before do
            data[:object_attributes][:ref] = 'a-random-branch'
            pipeline.update!(ref: 'a-random-branch')
          end

          context 'when notifications are enabled only for default branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default"
          end

          context 'when notifications are enabled only for protected branch' do
            it_behaves_like 'not sending email', branches_to_be_notified: "protected"
          end

          context 'when notifications are enabled only for default and protected branches' do
            it_behaves_like 'not sending email', branches_to_be_notified: "default_and_protected"
          end

          context 'when notifications are enabled only for all branches' do
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

    context 'with invalid recipients' do
      it 'skips the invalid email' do
        subject.recipients = "test@gitlab.com, invalid-email, , another-invalid valid@gitlab.com"

        expect_next_instance_of(PipelineNotificationWorker) do |worker|
          expect(worker).to receive(:perform).with(pipeline.id, "recipients" => ['test@gitlab.com', 'valid@gitlab.com'])
        end

        subject.execute(data)
      end
    end

    context 'when recipient contains angle brackets' do
      it 'removes the angle brackets' do
        subject.recipients = 'Name <valid@recipient.com>, Name 2 valid2@recipient.com'

        expect_next_instance_of(PipelineNotificationWorker) do |worker|
          expect(worker).to receive(:perform).with(pipeline.id,
            "recipients" => ['valid@recipient.com', 'valid2@recipient.com'])
        end

        subject.execute(data)
      end
    end

    context 'with child pipeline notifications' do
      before do
        stub_feature_flags(pipelines_email_notify_child_pipelines: true)
      end

      let(:child_pipeline) do
        create(:ci_pipeline, :failed,
          project: project,
          sha: project.commit('master').sha,
          ref: project.default_branch,
          source: :parent_pipeline
        )
      end

      let(:child_data) do
        Gitlab::DataBuilder::Pipeline.build(child_pipeline)
      end

      def run
        subject.execute(child_data)
      end

      context 'when notify_child_pipelines is enabled' do
        before do
          subject.notify_child_pipelines = true
        end

        it_behaves_like 'sending email'
      end

      context 'when notify_child_pipelines is disabled' do
        before do
          subject.notify_child_pipelines = false
        end

        it_behaves_like 'not sending email'
      end

      context 'when notify_child_pipelines is enabled for parent pipelines' do
        def run
          subject.execute(data) # regular pipeline data
        end

        before do
          subject.notify_child_pipelines = true
        end

        it_behaves_like 'sending email'
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(pipelines_email_notify_child_pipelines: false)
      end

      context 'with child pipeline' do
        let(:child_pipeline) do
          create(:ci_pipeline, :failed,
            project: project,
            sha: project.commit('master').sha,
            ref: project.default_branch,
            source: :parent_pipeline
          )
        end

        let(:child_data) do
          Gitlab::DataBuilder::Pipeline.build(child_pipeline)
        end

        def run
          subject.execute(child_data)
        end

        before do
          subject.notify_child_pipelines = false
          subject.recipients = recipients
        end

        it_behaves_like 'sending email'
      end
    end

    context 'with rate limiting' do
      let(:recipients) { 'a@gitlab.com,b@gitlab.com,c@gitlab.com' }

      before do
        subject.recipients = recipients
      end

      context 'when over the limit' do
        before do
          allow_next_instance_of(::Gitlab::Email::NamespaceRateLimiter) do |limiter|
            allow(limiter).to receive(:rate_limit_batch!).and_return(true)
          end
        end

        it 'suppresses the whole batch and does not enqueue', :aggregate_failures do
          expect(PipelineNotificationWorker).not_to receive(:new)

          subject.execute(data)
        end

        it 'charges the limiter with the full recipient count' do
          expect_next_instance_of(::Gitlab::Email::NamespaceRateLimiter) do |limiter|
            expect(limiter).to receive(:rate_limit_batch!).with(3).and_return(true)
          end

          subject.execute(data)
        end

        it 'builds the limiter scoped to the root namespace with the Pipelines Email buckets' do
          expect(::Gitlab::Email::NamespaceRateLimiter).to receive(:new).with(
            a_hash_including(
              root_namespace: project.root_namespace,
              hourly_bucket: :pipelines_email_outbound_emails_per_hour,
              daily_bucket: :pipelines_email_outbound_emails_per_day,
              feature_flag: :pipelines_email_email_rate_limit
            )
          ).and_call_original

          subject.execute(data)
        end

        it 'skips the limiter on the forced test path and still enqueues', :aggregate_failures do
          expect(::Gitlab::Email::NamespaceRateLimiter).not_to receive(:new)

          expect_next_instance_of(PipelineNotificationWorker) do |worker|
            expect(worker).to receive(:perform).with(
              pipeline.id, 'recipients' => %w[a@gitlab.com b@gitlab.com c@gitlab.com]
            )
          end

          subject.execute(data, force: true)
        end
      end

      context 'when under the limit' do
        before do
          allow_next_instance_of(::Gitlab::Email::NamespaceRateLimiter) do |limiter|
            allow(limiter).to receive(:rate_limit_batch!).and_return(false)
          end
        end

        it 'enqueues normally' do
          expect_next_instance_of(PipelineNotificationWorker) do |worker|
            expect(worker).to receive(:perform).with(
              pipeline.id, 'recipients' => %w[a@gitlab.com b@gitlab.com c@gitlab.com]
            )
          end

          subject.execute(data)
        end
      end

      context 'when the feature flag is disabled' do
        before do
          stub_feature_flags(pipelines_email_email_rate_limit: false)
        end

        it 'never consults the rate limiter and enqueues', :aggregate_failures do
          expect(::Gitlab::ApplicationRateLimiter).not_to receive(:throttled?)

          expect_next_instance_of(PipelineNotificationWorker) do |worker|
            expect(worker).to receive(:perform).with(
              pipeline.id, 'recipients' => %w[a@gitlab.com b@gitlab.com c@gitlab.com]
            )
          end

          subject.execute(data)
        end
      end

      context 'when emails are disabled for the project' do
        before do
          allow(project).to receive(:emails_disabled?).and_return(true)
        end

        it 'does not charge the limiter and does not enqueue', :aggregate_failures do
          expect(::Gitlab::Email::NamespaceRateLimiter).not_to receive(:new)
          expect(PipelineNotificationWorker).not_to receive(:new)

          subject.execute(data)
        end
      end
    end
  end
end
