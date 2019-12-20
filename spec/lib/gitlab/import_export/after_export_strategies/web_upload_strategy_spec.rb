# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy do
  include StubRequests

  let(:example_url) { 'http://www.example.com' }
  let(:strategy) { subject.new(url: example_url, http_method: 'post') }
  let!(:project) { create(:project, :with_export) }
  let!(:user) { build(:user) }

  subject { described_class }

  describe 'validations' do
    it 'only POST and PUT method allowed' do
      %w(POST post PUT put).each do |method|
        expect(subject.new(url: example_url, http_method: method)).to be_valid
      end

      expect(subject.new(url: example_url, http_method: 'whatever')).not_to be_valid
    end

    it 'onyl allow urls as upload urls' do
      expect(subject.new(url: example_url)).to be_valid
      expect(subject.new(url: 'whatever')).not_to be_valid
    end
  end

  describe '#execute' do
    it 'removes the exported project file after the upload' do
      allow(strategy).to receive(:send_file)
      allow(strategy).to receive(:handle_response_error)

      expect(project).to receive(:remove_exports)

      strategy.execute(user, project)
    end

    context 'when upload fails' do
      it 'stores the export error' do
        stub_full_request(example_url, method: :post).to_return(status: [404, 'Page not found'])

        strategy.execute(user, project)

        errors = project.import_export_shared.errors
        expect(errors).not_to be_empty
        expect(errors.first).to eq "Error uploading the project. Code 404: Page not found"
      end
    end
  end
end
