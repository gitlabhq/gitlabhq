# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::StuckProjectImportJobsWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe 'with scheduled import_status' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:project, :import_scheduled).import_state }

      before do
        import_state.update!(jid: '123')
      end
    end
  end

  describe 'with started import_status' do
    it_behaves_like 'stuck import job detection' do
      let(:import_state) { create(:project, :import_started).import_state }

      before do
        import_state.update!(jid: '123')
      end
    end
  end
end
