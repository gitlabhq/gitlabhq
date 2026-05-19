# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Designs, feature_category: :portfolio_management do
  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::DesignsType,
    exceptions: %w[widget_definition]

  describe '#as_json' do
    let(:design_collection) do
      instance_double(DesignManagement::DesignCollection, copy_state: 'ready')
    end

    let(:widget) do
      instance_double(WorkItems::Widgets::Designs, design_collection: design_collection)
    end

    subject(:representation) { described_class.new(widget).as_json }

    it 'exposes the design_collection' do
      expect(representation[:design_collection]).to include(copy_state: 'ready')
    end

    context 'when design_collection is nil' do
      let(:widget) do
        instance_double(WorkItems::Widgets::Designs, design_collection: nil)
      end

      it 'exposes nil design_collection' do
        expect(representation[:design_collection]).to be_nil
      end
    end
  end
end
