# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::OpenApi do
  describe 'class methods' do
    let(:klass) { Class.new.include(described_class) }

    describe '.add_open_api_documentation!' do
      before do
        allow(YAML).to receive(:load_file).and_return({ 'metadata' => { 'key' => 'value' } })
      end

      it 'calls the add_swagger_documentation method' do
        expect(klass).to receive(:add_swagger_documentation).with({ key: 'value' })

        klass.add_open_api_documentation!
      end
    end
  end
end
