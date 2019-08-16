# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::UsageDataCounters::NoteCounter, :clean_gitlab_redis_shared_state do
  shared_examples 'a note usage counter' do |event, noteable_type|
    describe ".count(#{event})" do
      it "increments the Note #{event} counter by 1" do
        expect do
          described_class.count(event, noteable_type)
        end.to change { described_class.read(event, noteable_type) }.by 1
      end
    end

    describe ".read(#{event})" do
      event_count = 5

      it "returns the total number of #{event} events" do
        event_count.times do
          described_class.count(event, noteable_type)
        end

        expect(described_class.read(event, noteable_type)).to eq(event_count)
      end
    end
  end

  it_behaves_like 'a note usage counter', :create, 'Snippet'
  it_behaves_like 'a note usage counter', :create, 'MergeRequest'
  it_behaves_like 'a note usage counter', :create, 'Commit'

  describe '.totals' do
    let(:combinations) do
      [
        [:create, 'Snippet', 3],
        [:create, 'MergeRequest', 4],
        [:create, 'Commit', 5]
      ]
    end

    let(:expected_totals) do
      { snippet_comment: 3,
        merge_request_comment: 4,
        commit_comment:  5 }
    end

    before do
      combinations.each do |event, noteable_type, n|
        n.times do
          described_class.count(event, noteable_type)
        end
      end
    end

    it 'can report all totals' do
      expect(described_class.totals).to include(expected_totals)
    end
  end

  describe 'unknown events or noteable_type' do
    using RSpec::Parameterized::TableSyntax

    let(:unknown_event_error) { Gitlab::UsageDataCounters::BaseCounter::UnknownEvent }

    where(:event, :noteable_type, :expected_count, :should_raise) do
      :create | 'Snippet'      | 1 | false
      :wibble | 'Snippet'      | 0 | true
      :create | 'MergeRequest' | 1 | false
      :wibble | 'MergeRequest' | 0 | true
      :create | 'Commit'       | 1 | false
      :wibble | 'Commit'       | 0 | true
      :create | 'Issue'        | 0 | false
      :wibble | 'Issue'        | 0 | false
    end

    with_them do
      it 'handles event' do
        if should_raise
          expect { described_class.count(event, noteable_type) }.to raise_error(unknown_event_error)
        else
          described_class.count(event, noteable_type)

          expect(described_class.read(event, noteable_type)).to eq(expected_count)
        end
      end
    end
  end
end
