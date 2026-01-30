# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JsRoutes, feature_category: :tooling do
  describe '.generate!' do
    let_it_be(:expected_base_path) do
      Rails.root.join('app/assets/javascripts/lib/utils/path_helpers')
    end

    describe 'outputted files' do
      before_all do
        described_class.generate!
      end

      it 'outputs utils.js file' do
        expect(File).to exist(File.join(expected_base_path, 'utils.js'))
      end

      it 'outputs core.js file' do
        expect(File).to exist(File.join(expected_base_path, 'core.js'))
      end

      it 'splits path helpers by namespace' do
        expect(File).to exist(File.join(expected_base_path, 'project.js'))
        expect(File).to exist(File.join(expected_base_path, 'group.js'))
      end
    end

    describe 'route_source_locations' do
      before do
        allow(described_class).to receive(:generate_path_helpers!).and_return(nil)
        allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations=)
        allow(Rails.application).to receive(:reload_routes!)
      end

      context 'when route_source_locations is disabled (production)' do
        before do
          allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations).and_return(false)
        end

        it 'temporarily enables route_source_locations, reloads routes, and restores setting after generation' do
          described_class.generate!

          expect(ActionDispatch::Routing::Mapper).to have_received(:route_source_locations=).with(true).ordered
          expect(Rails.application).to have_received(:reload_routes!).ordered
          expect(described_class).to have_received(:generate_path_helpers!).twice.ordered
          expect(ActionDispatch::Routing::Mapper).to have_received(:route_source_locations=).with(false).ordered
        end
      end

      context 'when route_source_locations is enabled (development)' do
        before do
          allow(ActionDispatch::Routing::Mapper).to receive(:route_source_locations).and_return(true)
        end

        it 'does not reload routes to avoid issues with caching' do
          described_class.generate!

          expect(Rails.application).not_to have_received(:reload_routes!)
        end
      end
    end
  end
end
