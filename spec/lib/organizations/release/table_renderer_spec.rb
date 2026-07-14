# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Organizations::Release::TableRenderer, feature_category: :organization do
  describe '#render' do
    it 'lists every stage and registered organization flag', :aggregate_failures do
      output = described_class.new.render

      expect(output).to include('title: Organizations platform release status')
      Organizations::Release.stages.each { |stage| expect(output).to include(stage.label) }
      Organizations::Release::Registry.instance.flags.each { |flag| expect(output).to include(flag.name) }
    end

    context 'when no organization flags are registered' do
      let(:registry) { instance_double(Organizations::Release::Registry, flags: []) }

      it 'renders a placeholder instead of an empty table', :aggregate_failures do
        output = described_class.new(registry: registry).render

        expect(output).to include('No organization flags are registered yet')
        expect(output).not_to match(/^\| Flag \|/)
      end
    end
  end
end
