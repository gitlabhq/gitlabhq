# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::AdvanceStageWorker, feature_category: :importers do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project, jid: '123') }
  let(:worker) { described_class.new }

  describe '#find_import_state' do
    it 'returns a ProjectImportState' do
      import_state.update_column(:status, 'started')

      found = worker.find_import_state(project.id)

      expect(found).to be_an_instance_of(ProjectImportState)
      expect(found.attributes.keys).to match_array(%w[id jid])
    end

    it 'returns nil if the project import is not running' do
      expect(worker.find_import_state(project.id)).to be_nil
    end
  end
end
