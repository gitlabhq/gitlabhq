# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::IntegrationList, feature_category: :integrations do
  let_it_be(:projects) { create_pair(:project, :small_repo) }
  let(:batch) { Project.where(id: projects.pluck(:id)) }
  let(:integration_hash) { { 'active' => 'true', 'category' => 'common' } }
  let(:association) { 'project' }

  subject { described_class.new(batch, integration_hash, association) }

  describe '#to_array' do
    it 'returns array of Integration, columns, and values' do
      expect(subject.to_array).to eq([
        Integration,
        %w[active category project_id],
        [['true', 'common', projects.first.id], ['true', 'common', projects.second.id]]
      ])
    end
  end
end
