# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::LogUtil do
  describe '.exportable_to_log_payload' do
    subject { described_class.exportable_to_log_payload(exportable) }

    context 'when exportable is a group' do
      let(:exportable) { build_stubbed(:group) }

      it 'returns hash with group keys' do
        expect(subject).to be_a(Hash)
        expect(subject.keys).to eq(%i[group_id group_name group_path])
      end
    end

    context 'when exportable is a project' do
      let(:exportable) { build_stubbed(:project) }

      it 'returns hash with project keys' do
        expect(subject).to be_a(Hash)
        expect(subject.keys).to eq(%i[project_id project_name project_path])
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
