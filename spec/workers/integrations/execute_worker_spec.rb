# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ExecuteWorker, '#perform', feature_category: :integrations do
  let_it_be(:integration) { create(:jira_integration) }

  let(:worker) { described_class.new }

  it 'executes integration with given data' do
    data = { test: 'test' }

    expect_next_found_instance_of(integration.class) do |integration|
      expect(integration).to receive(:execute).with(data)
    end

    worker.perform(integration.id, data)
  end

  it 'logs error messages' do
    error = StandardError.new('invalid URL')

    expect_next_found_instance_of(integration.class) do |integration|
      expect(integration).to receive(:execute).and_raise(error)
      expect(integration).to receive(:log_exception).with(error)
    end

    worker.perform(integration.id, {})
  end

  context 'when integration cannot be found' do
    it 'completes silently and does not log an error' do
      expect(Gitlab::IntegrationsLogger).not_to receive(:error)

      expect do
        worker.perform(non_existing_record_id, {})
      end.not_to raise_error
    end
  end

  context 'when the Gitlab::SilentMode is enabled' do
    before do
      allow(Gitlab::SilentMode).to receive(:enabled?).and_return(true)
    end

    it 'completes silently and does not log an error' do
      expect(Gitlab::IntegrationsLogger).not_to receive(:error)

      expect do
        worker.perform(non_existing_record_id, {})
      end.not_to raise_error
    end
  end

  context 'when object is wiki_page' do
    let_it_be(:container) { create(:project) }
    let_it_be(:wiki) { container.wiki }
    let_it_be(:content) { 'test content' }
    let_it_be(:wiki_page) { create(:wiki_page, container: container, content: content) }

    let(:object_kind) { 'wiki_page' }
    let(:slug) { wiki_page.slug }
    let(:version_id) { wiki_page.version.id }
    let(:args) do
      {
        object_kind: object_kind,
        project: {
          id: container.id
        },
        object_attributes: {
          slug: slug,
          version_id: version_id
        }
      }
    end

    it 'injects content into wiki_page' do
      expected_data = args.deep_merge(object_attributes: { content: content })

      expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(wiki)
      expect(wiki).to receive(:find_page).with(slug, version_id).and_return(wiki_page)
      expect_next_found_instance_of(integration.class) do |integration|
        expect(integration).to receive(:execute).with(expected_data)
      end

      worker.perform(integration.id, args)
    end

    context 'when parameter slug empty' do
      let(:slug) { '' }

      it 'uses existing data' do
        expected_data = args

        expect_next_found_instance_of(integration.class) do |integration|
          expect(integration).to receive(:execute).with(expected_data)
        end

        worker.perform(integration.id, args)
      end
    end

    context 'when parameter version_id empty' do
      let(:version_id) { '' }

      it 'uses existing data' do
        expected_data = args

        expect_next_found_instance_of(integration.class) do |integration|
          expect(integration).to receive(:execute).with(expected_data)
        end

        worker.perform(integration.id, args)
      end
    end

    context 'when wiki empty' do
      it 'uses existing data' do
        expected_data = args

        expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(nil)
        expect_next_found_instance_of(integration.class) do |integration|
          expect(integration).to receive(:execute).with(expected_data)
        end

        worker.perform(integration.id, args)
      end
    end

    context 'when wiki page empty' do
      it 'uses existing data' do
        expected_data = args

        expect(ProjectWiki).to receive(:find_by_id).with(container.id).and_return(wiki)
        expect(wiki).to receive(:find_page).with(slug, version_id).and_return(nil)
        expect_next_found_instance_of(integration.class) do |integration|
          expect(integration).to receive(:execute).with(expected_data)
        end

        worker.perform(integration.id, args)
      end
    end
  end
end
