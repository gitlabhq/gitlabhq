# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Internal Events matchers', :clean_gitlab_redis_shared_state, feature_category: :service_ping do
  let_it_be(:user_1) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:group_1) { create(:group) }
  let_it_be(:group_2) { create(:group) }
  let_it_be(:project_1) { create(:project, namespace: group_1) }

  before do
    allow(Gitlab::Tracking::EventValidator).to receive_message_chain(:new, :validate!)
  end

  def track_event(event: nil, user: nil, group: nil)
    Gitlab::InternalEvents.track_event(
      event || 'g_edit_by_sfe',
      user: user || user_1,
      namespace: group || group_1
    )
  end

  shared_examples 'matcher and negated matcher both raise expected error' do |(matcher, *args), expected_error|
    specify do
      expect do
        expect { track_event }.to send(matcher, *args)
      end.to raise_error ArgumentError, expected_error

      expect do
        expect { track_event }.to send(:"not_#{matcher}", *args)
      end.to raise_error ArgumentError, expected_error
    end
  end

  describe ':trigger_internal_events' do
    context 'when testing HTML with data attributes', type: :component do
      using RSpec::Parameterized::TableSyntax

      let(:event_name) { 'g_edit_by_sfe' }
      let(:label) { 'some_label' }
      let(:rendered_html) do
        <<-HTML
          <div>
            <a href="#" data-event-tracking="#{event_name}">Click me</a>
          </div>
        HTML
      end

      let(:capybara_node) { Capybara::Node::Simple.new(rendered_html) }

      where(:html_input) do
        [
          ref(:rendered_html),
          ref(:capybara_node)
        ]
      end

      with_them do
        context 'when using positive matcher' do
          it 'matches elements with correct tracking attribute' do
            expect(html_input).to trigger_internal_events(event_name).on_click
          end

          context 'with incorrect tracking attribute' do
            let(:event_name) { 'wrong_event' }

            it 'does not match elements' do
              expect do
                expect(html_input).to trigger_internal_events('g_edit_by_sfe')
              end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
            end
          end

          context 'with non existing tracking event' do
            let(:event_name) { 'wrong_event' }

            it 'does not match elements' do
              expect do
                expect(html_input).to trigger_internal_events(event_name)
              end.to raise_error(ArgumentError)
            end
          end

          context 'with additional properties' do
            let(:rendered_html) do
              <<-HTML
              <div>
                <a href="#" data-event-tracking="#{event_name}" data-event-label=\"#{label}\">Click me</a>
              </div>
              HTML
            end

            it 'matches elements' do
              expect(html_input).to trigger_internal_events(event_name).with(additional_properties: { label: label })
            end
          end

          context 'with tracking-load attribute' do
            let(:rendered_html) do
              <<-HTML
              <div>
                <a href="#" data-event-tracking="#{event_name}" data-event-tracking-load=\"true\">Click me</a>
              </div>
              HTML
            end

            it 'matches elements' do
              expect(rendered_html).to trigger_internal_events(event_name).on_load
            end
          end

          it 'raises error when multiple events are provided' do
            expect do
              expect(rendered_html).to trigger_internal_events(event_name, event_name)
            end.to raise_error(ArgumentError, /Providing multiple event names.*is only supported for block arguments/)
          end

          it 'raises error when using incompatible chain methods' do
            expect do
              expect(rendered_html).to trigger_internal_events(event_name).once
            end.to raise_error(ArgumentError, /Chain methods.*are only available for block arguments/)
          end
        end

        context 'when using negated matcher' do
          let(:rendered_html) { '<div></div>' }

          it 'matches elements without tracking attribute' do
            expect(rendered_html).not_to trigger_internal_events
          end

          it 'raises error when passing events to negated matcher' do
            expect do
              expect(rendered_html).not_to trigger_internal_events(event_name)
            end.to raise_error(ArgumentError, /Negated trigger_internal_events matcher accepts no arguments/)
          end

          it 'raises error when using chain methods with negated matcher' do
            expect do
              expect(rendered_html).not_to trigger_internal_events(event_name)
                                             .with(additional_properties: { label: label })
            end.to raise_error(ArgumentError, /Chain methods.*are unavailable for negated.*matcher/)
          end
        end
      end
    end

    context 'with backend events' do
      it 'raises error if no events are passed to :trigger_internal_events' do
        expect do
          expect { nil }.to trigger_internal_events
        end.to raise_error ArgumentError, 'trigger_internal_events matcher requires events argument'
      end

      it 'does not raises error if no events are passed to :not_trigger_internal_events' do
        expect do
          expect { nil }.to not_trigger_internal_events
        end.not_to raise_error
      end

      it_behaves_like 'matcher and negated matcher both raise expected error',
        [:trigger_internal_events, 'bad_event_name'],
        "Unknown event 'bad_event_name'! trigger_internal_events matcher accepts only existing events"

      it 'bubbles up failure messages' do
        expect do
          expect { nil }.to trigger_internal_events('g_edit_by_sfe')
        end.to raise_expectation_error_with <<~TEXT
          (Gitlab::InternalEvents).track_event("g_edit_by_sfe", *(any args))
              expected: 1 time with arguments: ("g_edit_by_sfe", *(any args))
              received: 0 times
        TEXT
      end

      it 'bubbles up failure messages for negated matcher' do
        expect do
          expect { track_event }.not_to trigger_internal_events('g_edit_by_sfe')
        end.to raise_expectation_error_with <<~TEXT
          (Gitlab::InternalEvents).track_event("g_edit_by_sfe", {:namespace=>#<Group id:#{group_1.id} @#{group_1.name}>, :user=>#<User id:#{user_1.id} @#{user_1.username}>})
              expected: 0 times with arguments: ("g_edit_by_sfe", anything)
              received: 1 time with arguments: ("g_edit_by_sfe", {:namespace=>#<Group id:#{group_1.id} @#{group_1.name}>, :user=>#<User id:#{user_1.id} @#{user_1.username}>})
        TEXT
      end

      it 'handles events that should not be triggered' do
        expect { track_event }.to not_trigger_internal_events('web_ide_viewed')
      end

      it 'ignores extra/irrelevant triggered events' do
        expect do
          # web_ide_viewed event should not cause a failure when we're only testing g_edit_by_sfe
          Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_1, namespace: group_1)
          Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
        end.to trigger_internal_events('g_edit_by_sfe')
      end

      it 'accepts chained event counts like #receive for multiple different events' do
        expect do
          # #track_event and #trigger_internal_events should be order independent
          Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
          Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_2, namespace: group_2)
          Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_2, namespace: group_2)
          Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_2, namespace: group_2)
          Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
        end.to trigger_internal_events('g_edit_by_sfe')
            .with(user: user_1, namespace: group_1)
            .at_least(:once)
          .and trigger_internal_events('web_ide_viewed')
            .with(user: user_2, namespace: group_2)
            .exactly(2).times
          .and trigger_internal_events('g_edit_by_sfe')
            .with(user: user_2, namespace: group_2)
            .once
      end

      context 'with additional properties' do
        let(:extra_track_params) { {} }
        let(:additional_properties) { { label: 'label1', value: 123, property: 'property1' } }
        let(:tracked_params) do
          { user: user_1, namespace: group_1, additional_properties: additional_properties.merge(extra_track_params) }
        end

        let(:expected_params) { tracked_params }

        subject(:assertion) do
          expect do
            Gitlab::InternalEvents.track_event('register_agent_at_kas', **tracked_params) # event that has all 3 params
          end.to trigger_internal_events('register_agent_at_kas')
              .with(expected_params)
              .once
        end

        shared_examples 'raises error for unexpected event args' do
          specify do
            expect { assertion }.to raise_error RSpec::Expectations::ExpectationNotMetError,
              /received :event with unexpected arguments/
          end
        end

        it 'accepts correct additional properties' do
          assertion
        end

        context 'with extra attributes' do
          let(:extra_track_params) { { kubernetes_version: 'other_prop' } }

          it 'accepts correct extra attributes' do
            assertion
          end
        end

        context "with wrong label value" do
          let(:expected_params) { tracked_params.deep_merge(additional_properties: { label: 'wrong_label' }) }

          it_behaves_like 'raises error for unexpected event args'
        end

        context 'with extra attributes expected but not tracked' do
          let(:expected_params) { tracked_params.deep_merge(additional_properties: { other_property: 'other_prop' }) }

          it_behaves_like 'raises error for unexpected event args'
        end

        context 'with extra attributes tracked but not expected' do
          let(:expected_params) do
            { user: user_1, namespace: group_1, additional_properties: { kubernetes_version: '1' } }
          end

          it_behaves_like 'raises error for unexpected event args'
        end
      end
    end
  end

  describe ':increment_usage_metrics' do
    it_behaves_like 'matcher and negated matcher both raise expected error',
      [:increment_usage_metrics],
      'increment_usage_metrics matcher requires key_paths argument'

    it_behaves_like 'matcher and negated matcher both raise expected error',
      [:increment_usage_metrics, 'redis_hll_counters.bad_metric_name'],
      "Cannot find metric definition for 'redis_hll_counters.bad_metric_name'!"

    it_behaves_like 'matcher and negated matcher both raise expected error',
      [:increment_usage_metrics, 'g_edit_by_sfe'],
      "Cannot find metric definition for 'g_edit_by_sfe' " \
        "-- did you mean 'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly'?"

    context 'when :increment_usage_metrics should fail' do
      context 'with a single metric failure' do
        subject(:assertion) do
          expect { nil }.to increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly')
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly to be incremented by 1
              ->  value went from 0 to 0
          TEXT
        end
      end

      context 'with a multiple metric failures' do
        subject(:assertion) do
          expect { nil }.to increment_usage_metrics(
            'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
            'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly'
          )
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly to be incremented by 1
              ->  value went from 0 to 0
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_monthly to be incremented by 1
              ->  value went from 0 to 0
          TEXT
        end
      end

      context 'with a multiple metric failures across chained assertions' do
        subject(:assertion) do
          expect { nil }
            .to increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly')
            .and increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_monthly')
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
             expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly to be incremented by 1
               ->  value went from 0 to 0

          ...and:

             expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_monthly to be incremented by 1
               ->  value went from 0 to 0
          TEXT
        end
      end

      context 'when failure may be due to a dirty redis state for unique metrics' do
        subject(:assertion) do
          expect { track_event }.to increment_usage_metrics(
            'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly'
          )
        end

        before do
          track_event # ensure event has already been tracked
        end

        it 'returns a meaningful failure message for :increment_usage_metrics with debugging tip' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly to be incremented by 1
              ->  value went from 1 to 1

            Debugging tip: Add the :clean_gitlab_redis_shared_state trait to reset event counters between examples.
          TEXT
        end
      end
    end

    context 'when :not_increment_usage_metrics should fail' do
      context 'with a single metric failure' do
        subject(:assertion) do
          expect { track_event }
            .not_to increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly')
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly not to be incremented
              ->  value went from 0 to 1
          TEXT
        end
      end

      context 'with a multiple metric failures' do
        subject(:assertion) do
          expect { track_event }.not_to increment_usage_metrics(
            'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
            'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly'
          )
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly not to be incremented
              ->  value went from 0 to 1
            expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_monthly not to be incremented
              ->  value went from 0 to 1
          TEXT
        end
      end

      context 'with a multiple metric failures across chained assertions' do
        subject(:assertion) do
          expect { track_event }
            .to not_increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly')
            .and not_increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_monthly')
        end

        it 'returns a meaningful failure message for :increment_usage_metrics' do
          expect { assertion }.to raise_expectation_error_with <<~TEXT
             expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_weekly not to be incremented
               ->  value went from 0 to 1

          ...and:

             expected metric redis_hll_counters.ide_edit.g_edit_by_sfe_monthly not to be incremented
               ->  value went from 0 to 1
          TEXT
        end
      end
    end

    it 'handles database-based metrics' do
      expect { create(:issue) }
        .to increment_usage_metrics(
          'usage_activity_by_stage.plan.issues',
          'usage_activity_by_stage_monthly.plan.issues')
    end

    it 'accepts chained metric counts like #change' do
      expect do
        Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
        Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_2, namespace: group_2)
        Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_1, namespace: group_1)
        Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_1, namespace: group_1)
        Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
      end.to increment_usage_metrics(
        'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
        'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly').by(2)
      .and increment_usage_metrics('counts.web_ide_views').from(0).to(2)
    end

    it 'handles non-integer values [ALPHA] (not strictly supported)' do
      expect { stub_const('Gitlab::VERSION', '11.10') }
        .to increment_usage_metrics('version')
        .to('11.10')
    end
  end

  context 'when chaining both matchers' do
    it 'handles triggering events that increment metrics' do
      expect { track_event }
        .to trigger_internal_events('g_edit_by_sfe').with(user: user_1, namespace: group_1)
        .and increment_usage_metrics(
          'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
          'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly')
    end

    it 'handles triggering events that do not increment metrics' do
      track_event # increment metric before triggering duplicate event

      expect { track_event }
        .to trigger_internal_events('g_edit_by_sfe').with(user: user_1, namespace: group_1)
        .and not_increment_usage_metrics(
          'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
          'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly')
    end

    it 'handles multiple triggered events and incremented metrics' do
      expect do
        Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
        Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_1, namespace: group_1)
      end.to trigger_internal_events('g_edit_by_sfe', 'web_ide_viewed')
        .with(user: user_1, namespace: group_1)
        .and increment_usage_metrics(
          'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
          'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly',
          'counts.web_ide_views')
    end

    it 'handles chaining multiple triggered events and incremented metrics with different args' do
      expect do
        Gitlab::InternalEvents.track_event('g_edit_by_sfe', user: user_1, namespace: group_1)
        Gitlab::InternalEvents.track_event('web_ide_viewed', user: user_2, namespace: group_2)
      end.to trigger_internal_events('g_edit_by_sfe')
          .with(user: user_1, namespace: group_1)
        .and trigger_internal_events('web_ide_viewed')
          .with(user: user_2, namespace: group_2)
        .and increment_usage_metrics(
          'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
          'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly',
          'counts.web_ide_views')
    end

    it 'accepts other chained matchers with #and' do
      expect do
        user_1.touch # make a different change we can test
        track_event
      end.to increment_usage_metrics(
        'redis_hll_counters.ide_edit.g_edit_by_sfe_weekly',
        'redis_hll_counters.ide_edit.g_edit_by_sfe_monthly')
      .and trigger_internal_events('g_edit_by_sfe')
      .and change { user_1.reload.updated_at }
      .and not_change { User.count }
    end

    describe 'instrumentation and testing contexts' do
      shared_examples 'works correctly' do
        specify do
          expect { subject }
            .to trigger_internal_events('g_edit_by_sfe')
            .and increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly')
        end
      end

      subject { track_event }

      context 'with retries', retry: 2 do
        context "with independent failure after the event" do
          subject do
            track_event

            raise 'Fail first attempt, causing a retry' if RSpec.current_example.attempts == 0
          end

          it_behaves_like "works correctly"
        end

        context "with independent failure before the event" do
          subject do
            raise 'Fail first attempt, causing a retry' if RSpec.current_example.attempts == 0

            track_event
          end

          it_behaves_like "works correctly"
        end

        context "with criteria met only on retry" do
          subject do
            track_event if RSpec.current_example.attempts > 0
          end

          it_behaves_like "works correctly"
        end
      end

      context 'without clearing Redis state between examples', clean_gitlab_redis_shared_state: false do
        it_behaves_like "works correctly"
      end

      context 'with snowplow not stubbed by default', :do_not_stub_snowplow_by_default do
        it_behaves_like "works correctly"
      end

      context 'with aggregate_failures', :aggregate_failures do
        context "with no failures" do
          it_behaves_like "works correctly"
        end

        context "with failures" do
          it "fails" do
            pending('This example should always fail. Protects against false positives.')

            # we can't test the error message because :aggregate_failures rescues errors
            expect { nil }.to(trigger_internal_events('g_edit_by_sfe'))
            expect { nil }.to(increment_usage_metrics('redis_hll_counters.ide_edit.g_edit_by_sfe_weekly'))
          end
        end
      end

      context 'when triggered from controllers' do
        context 'when using controller specs', type: :controller do
          controller(BaseActionController) do
            include ProductAnalyticsTracking

            track_internal_event :index, name: 'g_edit_by_sfe'

            def index
              render html: 'index page'
            end

            private

            def tracking_project_source; end

            def tracking_namespace_source; end
          end

          subject do
            sign_in user_1
            get :index
          end

          it_behaves_like "works correctly"
        end

        context 'when triggered from request specs', type: :request do
          # ideally, this spec should be completed with a new controller generated inside the test
          let_it_be(:project) { create(:project, :repository) }
          let_it_be(:user) { create(:user, maintainer_of: project) }

          subject do
            sign_in(user)
            post namespace_project_create_blob_path(
              namespace_id: project.namespace,
              project_id: project,
              id: 'master'
            ), params: {
              branch_name: 'master',
              file_name: 'docs/EXAMPLE_FILE',
              content: 'Added changes',
              commit_message: 'Create CHANGELOG'
            }
          end

          it_behaves_like "works correctly"
        end

        context 'when triggered from rails model lifecycle hooks' do
          let(:test_model) do
            Class.new(ApplicationRecord) do
              self.table_name = :merge_requests

              after_initialize do
                Gitlab::InternalEvents.track_event(
                  'create_merge_request',
                  user: user,
                  project: project
                )
              end

              attr_accessor :user, :project
            end
          end

          it 'works correctly' do
            expect { test_model.new(user: user_1, project: project_1) }
              .to trigger_internal_events('create_merge_request')
              .with(user: user_1, project: project_1)
              .and increment_usage_metrics('counts.merge_request_create')
          end
        end

        context 'when triggered from sidekiq worker', :sidekiq_inline do
          let(:test_worker) do
            Class.new do
              # `include ApplicationWorker` raises errors for unnamed classes
              def self.name
                'Gitlab::TestUsageWorker'
              end

              include ApplicationWorker

              def perform(event, user_id, namespace_id)
                Gitlab::InternalEvents.track_event(
                  event,
                  user: User.find(user_id),
                  namespace: Group.find(namespace_id)
                )
              end
            end
          end

          subject do
            stub_const('Gitlab::TestUsageWorker', test_worker)
            test_worker.perform_async(
              'g_edit_by_sfe',
              user_1.id,
              group_1.id
            )
          end

          it_behaves_like "works correctly"
        end

        context 'when triggered from migrations' do
          let(:migration) do
            Class.new(Gitlab::Database::Migration[Gitlab::Database::Migration.current_version]) do
              milestone '18.0'

              @_defining_file = 'db/migrate/00000000000000_example.rb'

              def up
                Gitlab::InternalEvents.track_event(
                  'g_edit_by_sfe',
                  user: User.first,
                  namespace: Group.first
                )
              end
            end
          end

          subject { migration.new.up }

          it_behaves_like "works correctly"
        end
      end
    end
  end

  context "when using the 'internal event tracking' shared example" do
    context 'with identifiers' do
      let(:event) { 'g_edit_by_sfe' }
      let(:user) { user_1 }
      let(:namespace) { group_1 }

      subject(:assertion) { track_event }

      it_behaves_like 'internal event tracking'
    end

    context 'with additional properties' do
      let(:event) { 'click_delete_pod' } # event with label property
      let(:user) { user_1 }
      let(:project) { project_1 }
      let(:expected_label) { 'Awesome label value' }

      subject(:assertion) do
        Gitlab::InternalEvents.track_event(
          event,
          user: user,
          project: project,
          additional_properties: { label: expected_label }
        )
      end

      it_behaves_like 'internal event tracking' do
        let(:additional_properties) { { label: expected_label } }
      end

      it_behaves_like 'internal event tracking' do
        let(:label) { expected_label }
      end

      context 'with incorrect value being provided in additional_properties.' do
        let(:unexpected_label) { 'BAD label value' }

        before do
          # Mark examples as pending so that a passing test will raise an error.
          pending('This example should always fail. Protects against false positives.')
        end

        it_behaves_like 'internal event tracking' do
          let(:additional_properties) { { label: unexpected_label } }
        end

        it_behaves_like 'internal event tracking' do
          let(:label) { unexpected_label }
        end
      end
    end

    context "with an event that has metrics using filters" do
      let(:event) { 'push_package_to_registry' }

      subject(:assertion) { track_event }

      before do
        # Mark examples as pending so that a passing test will raise an error.
        pending('This example should always fail. Protects against false positives.')
      end

      it_behaves_like 'internal event tracking'
    end
  end

  private

  def raise_expectation_error_with(error_message)
    error_matcher = an_object_satisfying do |actual_message|
      expect(actual_message).to eq error_message.chomp
    end

    raise_error RSpec::Expectations::ExpectationNotMetError, error_matcher
  end
end
