# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::SlackNotification do |factory:|
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:integration) { create(factory, branches_to_be_notified: 'all', project: project) }

    def usage_tracking_key(action)
      prefix = integration.send(:metrics_key_prefix)

      "#{prefix}_#{action}_notification"
    end

    it 'uses only known events', :aggregate_failures do
      described_class::SUPPORTED_EVENTS_FOR_USAGE_LOG.each do |action|
        expect(
          Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(usage_tracking_key(action))
        ).to be true
      end
    end

    context 'when hook data includes a user object' do
      let_it_be(:user) { create_default(:user) }

      shared_examples 'increases the usage data counter' do |event|
        let(:event_name) { usage_tracking_key(event) }

        subject(:execute) { integration.execute(data) }

        it 'increases the usage data counter' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter)
            .to receive(:track_event).with(event_name, values: user.id).and_call_original

          execute
        end

        it_behaves_like 'Snowplow event tracking with RedisHLL context' do
          let(:category) { described_class.to_s }
          let(:action) { 'perform_integrations_action' }
          let(:namespace) { project.namespace }
          let(:label) { 'redis_hll_counters.ecosystem.ecosystem_total_unique_counts_monthly' }
          let(:property) { event_name }
        end
      end

      context 'when event is not supported for usage log' do
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        it 'does not increase the usage data counter' do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter)
            .not_to receive(:track_event).with(usage_tracking_key(:pipeline), values: user.id)

          integration.execute(data)
        end
      end

      context 'for issue notification' do
        let_it_be(:issue) { create(:issue, project: project) }

        let(:data) { issue.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', :issue
      end

      context 'for push notification' do
        let(:data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

        it_behaves_like 'increases the usage data counter', :push
      end

      context 'for deployment notification' do
        let_it_be(:deployment) { create(:deployment, project: project, user: user) }

        let(:data) { Gitlab::DataBuilder::Deployment.build(deployment, deployment.status, Time.current) }

        it_behaves_like 'increases the usage data counter', :deployment
      end

      context 'for wiki_page notification' do
        let_it_be(:wiki_page) do
          create(:wiki_page, wiki: project.wiki, message: 'user created page: Awesome wiki_page')
        end

        let(:data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

        before do
          # Skip this method that is not relevant to this test to prevent having
          # to update project which is frozen
          allow(project.wiki).to receive(:after_wiki_activity)
        end

        it_behaves_like 'increases the usage data counter', :wiki_page
      end

      context 'for merge_request notification' do
        let_it_be(:merge_request) { create(:merge_request, source_project: project) }

        let(:data) { merge_request.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', :merge_request
      end

      context 'for note notification' do
        let_it_be(:issue_note) { create(:note_on_issue, project: project, note: 'issue note') }

        let(:data) { Gitlab::DataBuilder::Note.build(issue_note, user, :create) }

        it_behaves_like 'increases the usage data counter', :note
      end

      context 'for tag_push notification' do
        let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }
        let(:newrev) { '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b' } # gitlab-test: git rev-parse refs/tags/v1.1.0
        let(:ref) { 'refs/tags/v1.1.0' }
        let(:data) do
          Git::TagHooksService.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref }).send(:push_data)
        end

        it_behaves_like 'increases the usage data counter', :tag_push
      end

      context 'for confidential note notification' do
        let_it_be(:confidential_issue_note) do
          create(:note_on_issue, project: project, note: 'issue note', confidential: true)
        end

        let(:data) { Gitlab::DataBuilder::Note.build(confidential_issue_note, user, :create) }

        it_behaves_like 'increases the usage data counter', :confidential_note
      end

      context 'for confidential issue notification' do
        let_it_be(:issue) { create(:issue, project: project, confidential: true) }

        let(:data) { issue.to_hook_data(user) }

        it_behaves_like 'increases the usage data counter', :confidential_issue
      end
    end

    context 'when hook data does not include a user' do
      let(:data) { Gitlab::DataBuilder::Pipeline.build(create(:ci_pipeline, project: project)) }

      it 'does not increase the usage data counter' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        integration.execute(data)
      end
    end
  end
end
