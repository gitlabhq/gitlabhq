# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::LogUtil, feature_category: :importers do
  describe '.exportable_to_log_payload' do
    subject { described_class.exportable_to_log_payload(exportable) }

    let(:organization) { build_stubbed(:organization) }

    context 'when exportable is a group' do
      let(:exportable) { build_stubbed(:group, organization: organization) }

      it 'returns hash with group keys', :aggregate_failures do
        expect(subject).to be_a(Hash)
        expect(subject.keys).to match_array([Labkit::Fields::GL_ORGANIZATION_ID, :group_id, :group_name, :group_path])
        expect(subject[Labkit::Fields::GL_ORGANIZATION_ID]).to eq(exportable.organization_id)
      end
    end

    context 'when exportable is a project' do
      let(:exportable) { build_stubbed(:project, organization: organization) }

      it 'returns hash with project keys', :aggregate_failures do
        expect(subject).to be_a(Hash)
        expect(subject.keys)
          .to match_array([Labkit::Fields::GL_ORGANIZATION_ID, :project_id, :project_name, :project_path])
        expect(subject[Labkit::Fields::GL_ORGANIZATION_ID]).to eq(exportable.organization_id)
      end
    end

    context 'when exportable is a new record' do
      let(:exportable) { Project.new }

      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'when exportable is an unexpected type' do
      let(:exportable) { build_stubbed(:issue) }

      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end
  end
end
