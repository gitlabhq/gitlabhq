# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Loaders::AlertManagement::Alerts::AssigneesLoader do
  describe '#find' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:alert1) { create(:alert_management_alert, project: project, assignees: [user]) }
    let_it_be(:alert2) { create(:alert_management_alert, :all_fields, project: project) }
    let_it_be(:alert3) { create(:alert_management_alert, project: project) }
    let(:filter) { proc {} }

    subject do
      [
        described_class.new(alert1.id, filter).find,
        described_class.new(alert2.id, filter).find,
        described_class.new(alert3.id, filter).find
      ].map(&:sync)
    end

    it 'only queries once for alert assignees' do
      # One query for alert_assignees, one query for users
      expect { subject }.not_to exceed_query_limit(2)
    end

    it 'returns appropriate assignees for alerts' do
      expect(subject).to eq [alert1.assignees.to_a, alert2.assignees.to_a, alert3.assignees.to_a]
    end

    context 'with a filter' do
      let(:filter) { proc { |users| users.select { |u| u == user } } }

      it 'limits assignees by the filter' do
        expect(subject).to eq [alert1.assignees.to_a, alert2.assignees.to_a, alert3.assignees.to_a]
        expect(subject.all?(Gitlab::Graphql::FilterableArray)).to be_truthy

        filtered_result = subject.map { |assignees| assignees.filter_callback.call(assignees) }

        expect(filtered_result).to eq [[user], [], []]
      end
    end
  end
end
