# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectPipelineAnalyticsServiceBase, feature_category: :fleet_visibility do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: root_group) }
  let_it_be(:project) { create(:project, group: subgroup) }
  let_it_be(:current_user) { create(:user, reporter_of: root_group) }

  let(:container) { project }

  # Defines fetch_response so the query attribution can be observed via the
  # log_comment the HTTP client would send, without stubbing the subject.
  let(:test_class) do
    stub_const('TestService', Class.new(described_class) do
      attr_reader :captured_log_comment

      def fetch_response
        @captured_log_comment = Gitlab::Json::SafeParser.parse(ClickHouse::HttpClient.log_comment)
        ServiceResponse.success
      end
    end)
  end

  let(:service) { test_class.new(current_user: current_user, container: container, from_time: nil, to_time: nil) }

  subject(:result) { service.execute }

  describe '.fetch_response' do
    it 'raises a NotImplementedError for the base service' do
      base_service = described_class.new(current_user: current_user, container: container, from_time: nil, to_time: nil)

      expect do
        base_service.send(:fetch_response)
      end.to raise_error(NotImplementedError, "#{described_class} must implement `fetch_response`")
    end
  end

  describe '#execute' do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(true)
    end

    shared_examples 'attributes the ClickHouse query to the root namespace' do
      it 'annotates the ClickHouse log_comment with the root namespace', :aggregate_failures do
        expect(result).to be_success
        expect(service.captured_log_comment).to include('root_namespace_id' => root_group.id)
      end

      it 'scopes the attribution to the query block only' do
        result

        expect(Gitlab::ApplicationContext.current_context_attribute(Labkit::Fields::GL_ROOT_NAMESPACE_ID)).to be_nil
      end
    end

    # A cold container (reloaded, association not preloaded) mirrors how the
    # resolver builds it via Project.find_by_full_path, so the attribution must
    # not rely on a warm namespace association.
    context 'when the container is a project' do
      let(:container) { Project.find(project.id) }

      it_behaves_like 'attributes the ClickHouse query to the root namespace'
    end

    context 'when the container is a group' do
      let(:container) { Group.find(subgroup.id) }

      it_behaves_like 'attributes the ClickHouse query to the root namespace'
    end
  end
end
