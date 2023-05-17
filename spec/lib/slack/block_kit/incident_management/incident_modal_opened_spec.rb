# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Slack::BlockKit::IncidentManagement::IncidentModalOpened, feature_category: :incident_management do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:project_with_long_name) { create(:project, name: 'a b' * 76) }
  let_it_be(:response_url) { 'https://response.slack.com/id/123' }

  describe '#build' do
    subject(:payload) do
      described_class.new([project1, project2, project_with_long_name], response_url).build
    end

    it 'generates blocks for modal' do
      is_expected.to include({ type: 'modal', blocks: kind_of(Array), private_metadata: response_url })
    end

    it 'sets projects in the project selection' do
      project_list = payload[:blocks][1][:elements][0][:options]

      expect(project_list.first[:value]).to eq(project1.id.to_s)
      expect(project_list.last[:value]).to eq(project_with_long_name.id.to_s)
    end

    it 'sets initial project option as the first project path' do
      initial_project = payload[:blocks][1][:elements][0][:initial_option]

      expect(initial_project[:value]).to eq(project1.id.to_s)
    end

    it 'truncates the path value if more than 75 chars' do
      project_list = payload[:blocks][1][:elements][0][:options]

      expect(project_list.last.dig(:text, :text)).to eq(
        project_with_long_name.full_path.truncate(described_class::MAX_CHAR_LENGTH)
      )
    end
  end
end
