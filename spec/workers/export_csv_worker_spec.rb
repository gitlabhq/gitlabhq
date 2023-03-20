# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExportCsvWorker, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user) }

  def perform(params = {})
    described_class.new.perform(user.id, project.id, params)
  end

  it 'delegates call to IssuableExportCsvWorker' do
    expect(IssuableExportCsvWorker).to receive(:perform_async).with(:issue, user.id, project.id, anything)

    perform
  end
end
