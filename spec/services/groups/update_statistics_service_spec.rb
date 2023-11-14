# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UpdateStatisticsService, feature_category: :groups_and_projects do
  let_it_be(:group, reload: true) { create(:group) }

  let(:statistics) { %w[wiki_size] }

  subject(:service) { described_class.new(group, statistics: statistics) }

  describe '#execute', :aggregate_failures do
    context 'when group is nil' do
      let(:group) { nil }

      it 'does nothing' do
        expect(NamespaceStatistics).not_to receive(:new)

        result = service.execute

        expect(result).to be_error
      end
    end

    context 'with an existing group' do
      context 'when namespace statistics exists for the group' do
        it 'uses the existing statistics and refreshes them' do
          namespace_statistics = create(:namespace_statistics, namespace: group)

          expect(namespace_statistics).to receive(:refresh!).with(only: statistics.map(&:to_sym)).and_call_original

          result = service.execute

          expect(result).to be_success
        end
      end

      context 'when namespace statistics does not exist for the group' do
        it 'creates the statistics and refreshes them' do
          expect_next_instance_of(NamespaceStatistics) do |instance|
            expect(instance).to receive(:refresh!).with(only: statistics.map(&:to_sym)).and_call_original
          end

          result = nil

          expect do
            result = service.execute
          end.to change { NamespaceStatistics.count }.by(1)

          expect(result).to be_success
        end
      end
    end
  end
end
