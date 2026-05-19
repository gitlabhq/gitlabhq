# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::ErrorTracking, feature_category: :portfolio_management do
  # error_tracking exposes only identifier; stack_trace and status require external API calls
  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::ErrorTrackingType,
    exceptions: %w[widget_definition stack_trace status]

  describe '#as_json' do
    let(:widget) do
      instance_double(WorkItems::Widgets::ErrorTracking, sentry_issue_identifier: 12345)
    end

    subject(:representation) { described_class.new(widget).as_json }

    it 'exposes the sentry issue identifier' do
      expect(representation[:identifier]).to eq(12345)
    end

    context 'when identifier is nil' do
      let(:widget) do
        instance_double(WorkItems::Widgets::ErrorTracking, sentry_issue_identifier: nil)
      end

      it 'exposes nil identifier' do
        expect(representation[:identifier]).to be_nil
      end
    end
  end
end
