# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubRealtimeRepoEntity, feature_category: :importers do
  subject(:entity) { described_class.new(project) }

  let(:import_state) { instance_double(ProjectImportState, failed?: false, completed?: true) }
  let(:import_failures) { [instance_double(ImportFailure, exception_message: 'test error')] }
  let(:project) do
    instance_double(
      Project,
      id: 100500,
      import_status: 'importing',
      import_state: import_state,
      import_failures: import_failures,
      import_checksums: {}
    )
  end

  it 'exposes correct attributes' do
    data = entity.as_json

    expect(data.keys).to contain_exactly(:id, :import_status, :stats)
    expect(data[:id]).to eq project.id
    expect(data[:import_status]).to eq project.import_status
  end

  context 'when import stats is failed' do
    let(:import_state) { instance_double(ProjectImportState, failed?: true, completed?: true) }

    it 'includes import_error' do
      data = entity.as_json

      expect(data.keys).to contain_exactly(:id, :import_status, :stats, :import_error)
      expect(data[:import_error]).to eq 'test error'
    end
  end
end
