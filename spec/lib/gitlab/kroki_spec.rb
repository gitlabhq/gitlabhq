# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Kroki do
  using RSpec::Parameterized::TableSyntax

  describe '.formats' do
    def default_formats
      %w[bytefield c4plantuml ditaa erd graphviz nomnoml pikchr plantuml svgbob umlet vega vegalite wavedrom].freeze
    end

    subject { described_class.formats(Gitlab::CurrentSettings) }

    where(:enabled_formats, :expected_formats) do
      ''           | default_formats
      'blockdiag'  | default_formats + %w[actdiag blockdiag nwdiag packetdiag rackdiag seqdiag]
      'bpmn'       | default_formats + %w[bpmn]
      'excalidraw' | default_formats + %w[excalidraw]
    end

    with_them do
      before do
        kroki_formats =
          if enabled_formats.present?
            { enabled_formats => true }
          else
            {}
          end

        stub_application_setting(kroki_enabled: true, kroki_url: "http://localhost:8000", kroki_formats: kroki_formats)
      end

      it 'returns the expected formats' do
        expect(subject).to match_array(expected_formats)
      end
    end
  end
end
