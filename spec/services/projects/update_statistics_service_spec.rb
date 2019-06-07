# frozen_string_literal: true

require 'spec_helper'

describe Projects::UpdateStatisticsService do
  let(:service) { described_class.new(project, nil, statistics: statistics)}
  let(:statistics) { %w(repository_size) }

  describe '#execute' do
    context 'with a non-existing project' do
      let(:project) { nil }

      it 'does nothing' do
        expect_any_instance_of(ProjectStatistics).not_to receive(:refresh!)

        service.execute
      end
    end

    context 'with an existing project' do
      let(:project) { create(:project) }

      it 'refreshes the project statistics' do
        expect_any_instance_of(ProjectStatistics).to receive(:refresh!)
          .with(only: statistics.map(&:to_sym))
          .and_call_original

        service.execute
      end
    end
  end
end
