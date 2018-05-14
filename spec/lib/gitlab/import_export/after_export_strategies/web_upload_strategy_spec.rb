require 'spec_helper'

describe Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy do
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

      expect(project).to receive(:remove_exported_project_file)

      strategy.execute(user, project)
    end
  end
end
