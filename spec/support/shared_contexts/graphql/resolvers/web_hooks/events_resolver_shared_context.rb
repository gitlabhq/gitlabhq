# frozen_string_literal: true

RSpec.shared_examples 'resolving web hook logs' do
  let_it_be(:log_10m_ago) { create(:web_hook_log, web_hook: web_hook, created_at: 10.minutes.ago) }
  let_it_be(:log_2d_ago) { create(:web_hook_log, web_hook: web_hook, created_at: 2.days.ago) }
  let_it_be(:log_6d_ago) { create(:web_hook_log, web_hook: web_hook, created_at: 6.days.ago) }
  let_it_be(:log_8d_ago) { create(:web_hook_log, web_hook: web_hook, created_at: 8.days.ago) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::WebHooks::EventType.connection_type)
  end

  context 'and the user is authorized' do
    let(:current_user) { authorized_user }

    context 'when resolving multiple webhook events' do
      it 'returns webhook events for the last seven days' do
        expect(resolve_webhook_events).to contain_exactly(log_10m_ago, log_2d_ago, log_6d_ago)
      end

      context 'when timestamp range filter is provided' do
        it 'calls WebHooks::WebHookLogsFinder with the expected arguments' do
          start_time = 5.days.ago.iso8601
          end_time = 1.day.ago.iso8601
          expected_args = {
            start_time: Time.parse(start_time), end_time: Time.parse(end_time),
            lookahead: anything
          }

          expect_next_instance_of(::WebHooks::WebHookLogsFinder, web_hook, current_user, expected_args) do |finder|
            expect(finder).to receive(:execute)
          end

          resolve_webhook_events(timestamp_range: { start: start_time, end: end_time })
        end

        it 'raises an error when end is before start' do
          start_time = 2.days.ago.iso8601
          end_time = 4.days.ago.iso8601

          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'start must be before end') do
            resolve_webhook_events(timestamp_range: { start: start_time, end: end_time })
          end
        end

        it 'raises an error when timestamp range includes times older than 7 days ago' do
          start_time = 8.days.ago.iso8601
          end_time = 5.days.ago.iso8601

          expect_graphql_error_to_be_created(
            Gitlab::Graphql::Errors::ArgumentError, '`timestamp range` must be within the last 7 days'
          ) do
            resolve_webhook_events(timestamp_range: { start: start_time, end: end_time })
          end
        end
      end
    end

    context 'when resolving a single webhook event' do
      it 'returns the webhook event' do
        expect(
          resolve_single_webhook_event({ id: GitlabSchema.id_from_object(log_2d_ago) })
        ).to eq(log_2d_ago)
      end

      it 'returns an error when timestamp range is given' do
        expect_graphql_error_to_be_created(
          GraphQL::Schema::Validator::ValidationFailedError,
          'Only one of [id, timestampRange] arguments is allowed at the same time.'
        ) do
          resolve_single_webhook_event(
            {
              id: GitlabSchema.id_from_object(log_2d_ago),
              timestamp_range: { start: 5.days.ago.iso8601, end: 1.day.ago.iso8601 }
            }
          )
        end
      end
    end
  end

  context 'and the user is not authorized' do
    let(:current_user) { unauthorized_user }

    it { expect(resolve_webhook_events).to be_nil }
    it { expect(resolve_single_webhook_event({ id: GitlabSchema.id_from_object(log_2d_ago) })).to be_nil }
  end

  def resolve_webhook_events(args = {})
    resolve(described_class, obj: web_hook, args: args, ctx: { current_user: current_user })
  end

  def resolve_single_webhook_event(args = {})
    resolve(described_class.single, obj: web_hook, args: args, ctx: { current_user: current_user })
  end
end
