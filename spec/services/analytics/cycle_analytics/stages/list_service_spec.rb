# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::Stages::ListService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:value_stream) { Analytics::CycleAnalytics::ProjectValueStream.build_default_value_stream(project) }
  let(:stages) { subject.payload[:stages] }

  subject { described_class.new(parent: project, current_user: user).execute }

  before_all do
    project.add_reporter(user)
  end

  it 'returns only the default stages' do
    expect(stages.size).to eq(Gitlab::Analytics::CycleAnalytics::DefaultStages.all.size)
  end

  it 'provides the default stages as non-persisted objects' do
    expect(stages.map(&:id)).to all(be_nil)
  end
end
