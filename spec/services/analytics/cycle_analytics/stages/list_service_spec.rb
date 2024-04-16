# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stages::ListService, feature_category: :value_stream_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, reporter_of: project) }
  let_it_be(:project_namespace) { project.project_namespace.reload }

  let(:value_stream) { Analytics::CycleAnalytics::ValueStream.build_default_value_stream(project_namespace) }
  let(:stages) { subject.payload[:stages] }

  subject do
    described_class.new(parent: project_namespace, current_user: user, params: { value_stream: value_stream }).execute
  end

  it 'returns only the default stages' do
    expect(stages.size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
  end

  it 'provides the default stages as non-persisted objects' do
    expect(stages.map(&:id)).to all(be_nil)
  end
end
