# frozen_string_literal: true

RSpec.shared_examples 'issuable supports timelog creation service' do
  let_it_be(:time_spent) { 3600 }
  let_it_be(:spent_at) { Time.now }
  let_it_be(:summary) { "Test summary" }

  let(:service) { described_class.new(issuable, time_spent, spent_at, summary, user) }

  shared_examples 'success_response' do
    it 'successfully saves the timelog' do
      expect(Projects::TriggeredHooks).to receive(:new).with(
        issuable.is_a?(Issue) ? :issue_hooks : :merge_request_hooks,
        a_hash_including(changes: a_hash_including(total_time_spent: { previous: 0, current: time_spent }))
      ).and_call_original

      is_expected.to be_success

      timelog = subject.payload[:timelog]

      expect(timelog).to be_persisted
      expect(timelog.time_spent).to eq(time_spent)
      expect(timelog.spent_at).to eq(spent_at)
      expect(timelog.summary).to eq(summary)
      expect(timelog.issuable).to eq(issuable)
    end
  end

  context 'when the user does not have permission' do
    let(:user) { create(:user) }

    it 'returns an error' do
      is_expected.to be_error

      expect(subject.message).to eq(
        "#{issuable.base_class_name} doesn't exist or you don't have permission to add timelog to it.")
      expect(subject.http_status).to eq(404)
    end
  end

  context 'when the user has permissions' do
    let(:user) { author }

    before do
      users_container.add_reporter(user)
    end

    context 'when spent_at is in the future' do
      let_it_be(:spent_at) { Time.now + 2.hours }

      it 'returns an error' do
        is_expected.to be_error

        expect(subject.message).to eq("Spent at can't be a future date and time.")
        expect(subject.http_status).to eq(404)
      end
    end

    context 'when time_spent is zero' do
      let_it_be(:time_spent) { 0 }

      it 'returns an error' do
        is_expected.to be_error

        expect(subject.message).to eq("Time spent can't be zero.")
        expect(subject.http_status).to eq(404)
      end
    end

    context 'when time_spent is nil' do
      let_it_be(:time_spent) { nil }

      it 'returns an error' do
        is_expected.to be_error

        expect(subject.message).to eq("Time spent can't be blank")
        expect(subject.http_status).to eq(404)
      end
    end

    context 'when the timelog save fails' do
      before do
        allow_next_instance_of(Timelog) do |timelog|
          allow(timelog).to receive(:save).and_return(false)
        end
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(subject.message).to eq('Failed to save timelog')
      end
    end

    context 'when the creation completes successfully' do
      it_behaves_like 'success_response'
    end
  end
end

RSpec.shared_examples 'issuable does not support timelog creation service' do
  let_it_be(:time_spent) { 3600 }
  let_it_be(:spent_at) { Time.now }
  let_it_be(:summary) { "Test summary" }

  let(:service) { described_class.new(issuable, time_spent, spent_at, summary, user) }

  shared_examples 'error_response' do
    it 'returns an error' do
      is_expected.to be_error

      issuable_type = if issuable.nil?
                        'Issuable'
                      else
                        issuable.base_class_name
                      end

      expect(subject.message).to eq(
        "#{issuable_type} doesn't exist or you don't have permission to add timelog to it."
      )
      expect(subject.http_status).to eq(404)
    end
  end

  context 'when the user does not have permission' do
    let(:user) { create(:user) }

    it_behaves_like 'error_response'
  end

  context 'when the user has permissions' do
    let(:user) { author }

    before do
      users_container.add_reporter(user)
    end

    it_behaves_like 'error_response'
  end
end
