require 'spec_helper'

describe RepositoryArchiveCleanUpService, services: true do
  describe '#execute' do
    let(:path) { Gitlab.config.gitlab.repository_downloads_path }

    subject(:service) { described_class.new }

    context 'when the downloads directory does not exist' do
      it 'does not remove any archives' do
        expect(File).to receive(:directory?).with(path).and_return(false)

        expect(service).not_to receive(:clean_up_old_archives)
        expect(service).not_to receive(:clean_up_empty_directories)

        service.execute
      end
    end

    context 'when the downloads directory exists' do
      it 'removes old archives' do
        expect(File).to receive(:directory?).with(path).and_return(true)

        expect(service).to receive(:clean_up_old_archives)
        expect(service).to receive(:clean_up_empty_directories)

        service.execute
      end
    end
  end
end
