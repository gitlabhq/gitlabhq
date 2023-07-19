# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::DownloadService, feature_category: :groups_and_projects do
  describe 'File service' do
    before do
      @user = create(:user)
      @project = create(:project, creator_id: @user.id, namespace: @user.namespace)
    end

    context 'for a URL that is not on allowlist' do
      before do
        url = 'https://code.jquery.com/jquery-2.1.4.min.js'
        @link_to_file = download_file(@project, url)
      end

      it { expect(@link_to_file).to eq(nil) }
    end

    context 'for URLs that are on the allowlist' do
      before do
        # `ssrf_filter` resolves the hostname. See https://github.com/carrierwaveuploader/carrierwave/commit/91714adda998bc9e8decf5b1f5d260d808761304
        stub_request(:get, %r{http://[\d.]+/rails_sample.jpg}).to_return(body: File.read(Rails.root + 'spec/fixtures/rails_sample.jpg'))
        stub_request(:get, %r{http://[\d.]+/doc_sample.txt}).to_return(body: File.read(Rails.root + 'spec/fixtures/doc_sample.txt'))
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
