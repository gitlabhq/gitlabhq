# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'timebox resource event validations' do
  describe 'validations' do
    context 'when issue and merge_request are both nil' do
      subject { build(described_class.name.underscore.to_sym, issue: nil, merge_request: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when issue and merge_request are both set' do
      subject { build(described_class.name.underscore.to_sym, issue: build(:issue), merge_request: build(:merge_request)) }

      it { is_expected.not_to be_valid }
    end

    context 'when issue is set' do
      subject { create(described_class.name.underscore.to_sym, issue: create(:issue), merge_request: nil) }

      it { is_expected.to be_valid }
    end

    context 'when merge_request is set' do
      subject { create(described_class.name.underscore.to_sym, issue: nil, merge_request: create(:merge_request)) }

      it { is_expected.to be_valid }
    end
  end
end

RSpec.shared_examples 'timebox resource event states' do
  describe 'states' do
    [Issue, MergeRequest].each do |klass|
      klass.available_states.each do |state|
        it "supports state #{state.first} for #{klass.name.underscore}" do
          model = create(klass.name.underscore, state: state[0])
          key = model.class.name.underscore
          event = build(described_class.name.underscore.to_sym, key => model, state: model.state)

          expect(event.state).to eq(state[0])
        end
      end
    end
  end
end

RSpec.shared_examples 'queryable timebox action resource event' do |expected_results_for_actions|
  [Issue, MergeRequest].each do |klass|
    expected_results_for_actions.each do |action, expected_result|
      it "is #{expected_result} for action #{action} on #{klass.name.underscore}" do
        model = build(klass.name.underscore)
        key = model.class.name.underscore
        event = build(described_class.name.underscore.to_sym, key => model, action: action)

        expect(event.send(query_method)).to eq(expected_result)
      end
    end
  end
end

RSpec.shared_examples 'timebox resource event actions' do
  describe '#added?' do
    it_behaves_like 'queryable timebox action resource event', { add: true, remove: false } do
      let(:query_method) { :add? }
    end
  end

  describe '#removed?' do
    it_behaves_like 'queryable timebox action resource event', { add: false, remove: true } do
      let(:query_method) { :remove? }
    end
  end
end

RSpec.shared_examples 'timebox resource tracks issue metrics' do |type|
  describe '#issue_usage_metrics' do
    it 'tracks usage for issues' do
      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:"track_issue_#{type}_changed_action")

      create(described_class.name.underscore.to_sym, issue: create(:issue))
    end

    it 'does not track usage for merge requests' do
      expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:"track_issue_#{type}_changed_action")

      create(described_class.name.underscore.to_sym, merge_request: create(:merge_request))
    end
  end
end
