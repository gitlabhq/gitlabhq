# frozen_string_literal: true

RSpec::Matchers.define :have_snapshot do |date, expected_states|
  match do |actual_snapshots|
    snapshot = actual_snapshots.find { |snapshot| snapshot.date == date }

    @snapshot_not_found = snapshot.nil?
    @item_states_not_found = []
    @not_eq_error = nil

    break false if @snapshot_not_found

    expected_states.each do |expected_state|
      actual_state = snapshot.item_states.find { |state| state[:item_id] == expected_state[:item_id] }

      if actual_state.nil?
        @item_states_not_found << expected_state[:issue_id]
      else
        default_state = {
          weight: 0,
          start_state: ResourceStateEvent.states[:opened],
          end_state: ResourceStateEvent.states[:opened],
          parent_id: nil,
          children_ids: Set.new
        }
        begin
          expect(actual_state.to_h).to eq(default_state.merge(expected_state))
        rescue RSpec::Expectations::ExpectationNotMetError => e
          @error_item_title = WorkItem.find(expected_state[:item_id]).title
          @not_eq_error = e

          raise
        end
      end
    end
  end

  failure_message do |_|
    break "No snapshot found for the given date #{date}" if @snapshot_not_found

    messages = []

    messages << <<~MESSAGE
      Expected the snapshot on #{date} to match the expected snapshot.

      Errors:
    MESSAGE

    messages << "Item states not found for: #{@item_states_not_found.join(', ')}" unless @item_states_not_found.empty?

    messages << "`#{@error_item_title}` does not have the expected states.\n#{@not_eq_error}" if @not_eq_error

    messages.join("\n")
  end
end
