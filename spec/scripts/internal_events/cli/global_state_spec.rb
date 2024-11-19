# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../scripts/internal_events/cli'

RSpec.describe InternalEventsCli::GlobalState, :aggregate_failures, :silence_stdout, feature_category: :service_ping do # rubocop:disable RSpec/SpecFilePathFormat -- match directory structure
  let(:global_state) { described_class.new }

  shared_examples 'loads definition files' do
    it 'loads the event definitions' do
      expect(definitions).to all be_a(expected_class)
      expect(definitions).to all satisfy { |definition| definition.file_path.present? }
    end

    it 'handles empty definition files' do
      allow(YAML).to receive(:safe_load).and_return(nil)

      expect { definitions }.not_to raise_error
      expect(definitions).to be_empty
    end

    it 'handles invalid definition files' do
      allow(YAML).to receive(:safe_load).and_return(['junk content'])

      expect { definitions }.not_to raise_error
      expect(definitions).to be_empty
    end

    it 'can be reloaded' do
      # Use `#product_group` as a proxy for any field present in all definitions
      expect(definitions).to all satisfy { |definition| definition.product_group.present? }

      # Stub file contents on reload
      allow(YAML).to receive(:safe_load).and_return({})

      # Calling again should change nothing
      expect(definitions).to all satisfy { |definition| definition.product_group.present? }

      global_state.reload_definitions

      # Defintions should be reloaded with stubs
      expect { definitions }.not_to raise_error
      expect(definitions).to all satisfy { |definition| definition.product_group.nil? }
    end

    private

    def definitions
      global_state.send(method)
    end
  end

  describe "#events" do
    let(:expected_class) { InternalEventsCli::ExistingEvent }
    let(:method) { :events }

    it_behaves_like 'loads definition files'
  end

  describe "#metrics" do
    let(:expected_class) { InternalEventsCli::ExistingMetric }
    let(:method) { :metrics }

    it_behaves_like 'loads definition files'
  end
end
