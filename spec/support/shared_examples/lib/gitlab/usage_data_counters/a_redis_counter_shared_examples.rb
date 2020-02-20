# frozen_string_literal: true

RSpec.shared_examples 'a redis usage counter' do |thing, event|
  describe ".count(#{event})", :clean_gitlab_redis_shared_state do
    it "increments the #{thing} #{event} counter by 1" do
      expect do
        described_class.count(event)
      end.to change { described_class.read(event) }.by 1
    end
  end

  describe ".read(#{event})", :clean_gitlab_redis_shared_state do
    event_count = 5

    it "returns the total number of #{event} events" do
      event_count.times do
        described_class.count(event)
      end

      expect(described_class.read(event)).to eq(event_count)
    end
  end
end

RSpec.shared_examples 'a redis usage counter with totals' do |prefix, events|
  describe 'totals', :clean_gitlab_redis_shared_state do
    before do
      events.each do |k, n|
        n.times do
          described_class.count(k)
        end
      end
    end

    let(:expected_totals) do
      events.transform_keys { |k| "#{prefix}_#{k}".to_sym }
    end

    it 'can report all totals' do
      expect(described_class.totals).to include(expected_totals)
    end
  end

  # Override these let-bindings to adjust the unknown events tests
  let(:unknown_event) { described_class::UnknownEvent }
  let(:bad_event) { :wibble }

  describe 'unknown events' do
    it 'cannot increment' do
      expect { described_class.count(bad_event) }.to raise_error unknown_event
    end

    it 'cannot read' do
      expect { described_class.read(bad_event) }.to raise_error unknown_event
    end
  end
end
