# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::StandardContext do
  let_it_be(:project) { create(:project) }
  let_it_be(:namespace) { create(:namespace) }

  let(:snowplow_context) { subject.to_context }

  describe '#to_context' do
    context 'default fields' do
      context 'environment' do
        shared_examples 'contains environment' do |expected_environment|
          it 'contains environment' do
            expect(snowplow_context.to_json.dig(:data, :environment)).to eq(expected_environment)
          end
        end

        context 'development or test' do
          include_examples 'contains environment', 'development'
        end

        context 'staging' do
          before do
            allow(Gitlab).to receive(:staging?).and_return(true)
          end

          include_examples 'contains environment', 'staging'
        end

        context 'production' do
          before do
            allow(Gitlab).to receive(:com_and_canary?).and_return(true)
          end

          include_examples 'contains environment', 'production'
        end
      end

      it 'contains source' do
        expect(snowplow_context.to_json.dig(:data, :source)).to eq(described_class::GITLAB_RAILS_SOURCE)
      end
    end

    context 'with extra data' do
      subject { described_class.new(foo: 'bar') }

      it 'creates a Snowplow context with the given data' do
        expect(snowplow_context.to_json.dig(:data, :foo)).to eq('bar')
      end
    end

    context 'with namespace' do
      subject { described_class.new(namespace: namespace) }

      it 'creates a Snowplow context without namespace and project' do
        expect(snowplow_context.to_json.dig(:data, :namespace_id)).to be_nil
        expect(snowplow_context.to_json.dig(:data, :project_id)).to be_nil
      end
    end

    context 'with project' do
      subject { described_class.new(project: project) }

      it 'creates a Snowplow context without namespace and project' do
        expect(snowplow_context.to_json.dig(:data, :namespace_id)).to be_nil
        expect(snowplow_context.to_json.dig(:data, :project_id)).to be_nil
      end
    end

    context 'with project and namespace' do
      subject { described_class.new(namespace: namespace, project: project) }

      it 'creates a Snowplow context without namespace and project' do
        expect(snowplow_context.to_json.dig(:data, :namespace_id)).to be_nil
        expect(snowplow_context.to_json.dig(:data, :project_id)).to be_nil
      end
    end
  end
end
