# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DownloadService do
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
        stub_request(:get, 'http://mycompany.fogbugz.com/rails_sample.jpg').to_return(body: File.read(Rails.root + 'spec/fixtures/rails_sample.jpg'))
        stub_request(:get, 'http://mycompany.fogbugz.com/doc_sample.txt').to_return(body: File.read(Rails.root + 'spec/fixtures/doc_sample.txt'))
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
