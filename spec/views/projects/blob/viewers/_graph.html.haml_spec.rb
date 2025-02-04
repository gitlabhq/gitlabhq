# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/blob/viewers/_graph.html.haml', feature_category: :source_code_management do
  include FakeBlobHelpers

  let(:project) { build(:project) }

  let(:data) do
    <<-SPEC.strip_heredoc
      @startuml
      Bob -> Alice : hello
      @enduml
    SPEC
  end

  let(:blob) { fake_blob(path: 'simple.puml', data: data) }
  let(:viewer) { BlobViewer::Graph.new(blob) }

  def render_view
    render partial: 'projects/blob/viewers/graph', locals: { viewer: viewer }
  end

  context 'with graph view for' do
    shared_examples 'render file with expectation' do |extension, content, expectation|
      describe "#{extension} files" do
        let(:blob) { fake_blob(path: "simple.#{extension}", data: content) }

        it 'render rich content' do
          stub_application_setting(plantuml_enabled: true, plantuml_url: "http://localhost:8080")
          stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8080")
          render_view

          expect(rendered).to include(expectation)
        end
      end
    end

    it_behaves_like 'render file with expectation', 'puml', "@startuml\nBob -> Alice : hello\n@enduml",
      'http://localhost:8080/png/U9npA2v9B2efpStXSifFKj2rKt3CoKnELR1Io4ZDoSddSaZDIm590W04uWpA'

    it_behaves_like 'render file with expectation', 'mermaid', "graph TD;\nA-->B;",
      'js-render-mermaid'

    it_behaves_like 'render file with expectation', 'dot', "graph {\na -- b;\n}",
      'http://localhost:8080/graphviz/svg/eNpLL0osyFCo5kpU0NVVSLLmquUCADVJBOE='

    it_behaves_like 'render file with expectation', 'noml',
      "[Pirate|eyeCount: Int|raid();pillage()|\n  [beard]--[parrot]\n  [beard]-:>[foul mouth]\n]",
      'http://localhost:8080/nomnoml/svg/eNqLDsgsSixJrUmtTHXOL80rsVLwzCupKUrMTNHQtC7IzMlJTE_V0KzhUlCITkpNLEqJ1dWNLkgsKsoviUUSs7KLTssvzVHIzS8tyYjliuUCAE_tHdw='
  end
end
