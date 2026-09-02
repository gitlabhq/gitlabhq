# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::HttpClient, feature_category: :database do
  describe '.log_comment' do
    it 'serializes the available context attributes and omits the rest' do
      user = build_stubbed(:user, id: 42)
      group = build_stubbed(:group, id: 7, path: 'gitlab-org', traversal_ids: [7])

      Labkit::Correlation::CorrelationId.use_id('cid1') do
        Gitlab::ApplicationContext.with_context(user: user, namespace: group, feature_category: 'database') do
          expect(Namespace).not_to receive(:find_by_full_path)

          expect(Gitlab::Json::SafeParser.parse(described_class.log_comment)).to eq(
            'correlation_id' => 'cid1',
            'user_id' => 42,
            'root_namespace_id' => 7,
            'application' => Gitlab.process_name,
            'feature_category' => 'database'
          )
        end
      end
    end
  end

  describe 'root_namespace_id' do
    let_it_be(:root) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: root) }
    let_it_be(:project) { create(:project, group: subgroup) }

    def emitted
      Gitlab::Json::SafeParser.parse(described_class.log_comment)['root_namespace_id']
    end

    it 'is taken from the context when a namespace is present' do
      Gitlab::ApplicationContext.with_context(namespace: subgroup) do
        expect(emitted).to eq(root.id)
      end
    end

    it 'is omitted when only a project is present and its namespace is not loaded' do
      Gitlab::ApplicationContext.with_context(project: Project.find(project.id)) do
        expect(emitted).to be_nil
      end
    end

    it 'is omitted when there is no namespace or project' do
      Gitlab::ApplicationContext.with_context(feature_category: 'database') do
        expect(Gitlab::Json::SafeParser.parse(described_class.log_comment))
          .not_to have_key('root_namespace_id')
      end
    end
  end

  describe '.build_post_proc' do
    it 'posts to a URL carrying the escaped log comment' do
      allow(described_class).to receive(:log_comment).and_return('{"correlation_id":"cid 1"}')
      response = instance_double(HTTParty::Response, body: '{}', code: 200, headers: {})

      expect(Gitlab::HTTP).to receive(:post)
        .with('http://ch:8123/?database=main&log_comment=%7B%22correlation_id%22%3A%22cid+1%22%7D', anything)
        .and_return(response)

      described_class.build_post_proc.call('http://ch:8123/?database=main', {}, { 'query' => 'SELECT 1' })
    end
  end
end
