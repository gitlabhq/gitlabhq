require 'spec_helper'

describe Projects::DownloadService do
  describe 'File service' do
    before do
      @user = create(:user)
      @project = create(:project, creator_id: @user.id, namespace: @user.namespace)
    end

    context 'for a URL that is not on whitelist' do
      before do
        url = 'https://code.jquery.com/jquery-2.1.4.min.js'
        @link_to_file = download_file(@project, url)
      end

      it { expect(@link_to_file).to eq(nil) }
    end

    context 'for URLs that are on the whitelist' do
      before do
        sham_rack_app = ShamRack.at('mycompany.fogbugz.com').stub
        sham_rack_app.register_resource('/rails_sample.jpg', File.read(Rails.root + 'spec/fixtures/rails_sample.jpg'), 'image/jpg')
        sham_rack_app.register_resource('/doc_sample.txt', File.read(Rails.root + 'spec/fixtures/doc_sample.txt'), 'text/plain')
      end

      after do
        ShamRack.unmount_all
      end

      context 'an image file' do
        before do
          url = 'http://mycompany.fogbugz.com/rails_sample.jpg'
          @link_to_file = download_file(@project, url)
        end

        it { expect(@link_to_file).to have_key(:alt) }
        it { expect(@link_to_file).to have_key(:url) }
        it { expect(@link_to_file[:url]).to match('rails_sample.jpg') }
        it { expect(@link_to_file[:alt]).to eq('rails_sample') }
      end

      context 'a txt file' do
        before do
          url = 'http://mycompany.fogbugz.com/doc_sample.txt'
          @link_to_file = download_file(@project, url)
        end

        it { expect(@link_to_file).to have_key(:alt) }
        it { expect(@link_to_file).to have_key(:url) }
        it { expect(@link_to_file[:url]).to match('doc_sample.txt') }
        it { expect(@link_to_file[:alt]).to eq('doc_sample.txt') }
      end
    end
  end

  def download_file(repository, url)
    Projects::DownloadService.new(repository, url).execute
  end
end
