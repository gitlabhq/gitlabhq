# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::Graph, feature_category: :source_code_management do
  include FakeBlobHelpers

  let_it_be(:project) { create(:project, :repository) }

  describe '.can_render?' do
    described_class::INTERNAL_EXTENSIONS.each do |tested_extension|
      context 'with internal resolved extension' do
        let(:blob) { fake_blob(path: "simple.#{tested_extension}") }

        it "#{tested_extension} returns true" do
          expect(described_class.can_render?(blob)).to be_truthy
        end
      end
    end

    described_class::PLANTUML_EXTENSIONS.each do |tested_extension|
      context 'with PlantUML extension' do
        let(:blob) { fake_blob(path: "simple.#{tested_extension}") }

        context 'when PlantUML is enabled' do
          it "#{tested_extension} returns true" do
            stub_application_setting(plantuml_enabled: true)
            expect(described_class.can_render?(blob)).to be_truthy
          end
        end

        context 'when PlantUML is disabled' do
          it "#{tested_extension} returns false" do
            expect(described_class.can_render?(blob)).to be_falsey
          end
        end
      end
    end

    described_class::KROKI_EXTENSIONS.each do |tested_extension|
      context 'with Kroki extension' do
        let(:blob) { fake_blob(path: "simple.#{tested_extension}") }

        context 'when Kroki is enabled' do
          it "#{tested_extension} returns true" do
            stub_application_setting(kroki_enabled: true)
            expect(described_class.can_render?(blob)).to be_truthy
          end
        end

        context 'when Kroki is disabled' do
          it "#{tested_extension} returns false" do
            expect(described_class.can_render?(blob)).to be_falsey
          end
        end
      end
    end
  end

  describe '.graph_format' do
    described_class.extensions.each do |tested_extension|
      context 'with accepted graph file' do
        let(:blob) { fake_blob(path: "simple.#{tested_extension}") }

        it "returns valid graph format for #{tested_extension}" do
          expect(described_class.graph_format(blob)).not_to be_nil
        end
      end
    end
  end

  describe '#banzai_render_context' do
    let(:blob) { fake_blob(path: "simple.puml", data: '') }

    subject(:viewer) { described_class.new(blob) }

    it 'returns context needed for banzai rendering' do
      expect(viewer.banzai_render_context.keys).to eq([:cache_key])
    end
  end
end
