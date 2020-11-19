# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ImportCsvService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) do
    uploader = FileUploader.new(project)
    uploader.store!(file)

    described_class.new(user, project, uploader)
  end

  include_examples 'issuable import csv service', 'issue' do
    let(:issuables) { project.issues }
    let(:email_method) { :import_issues_csv_email }
  end
end
