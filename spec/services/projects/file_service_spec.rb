require 'spec_helper'

describe Projects::FileService do
  before(:each) { enable_observers }
  after(:each) { disable_observers }

  describe 'File service' do
    before do
      @user = create :user
      @project = create :project, creator_id: @user.id, namespace: @user.namespace
    end

    context 'for valid gif file' do
      before do
        gif = fixture_file_upload(Rails.root + 'spec/fixtures/banana_sample.gif', 'image/gif')
        @link_to_image = upload_image(@project.repository, { 'markdown_file' => gif }, "http://test.example/")
      end

      it { expect(@link_to_image).to have_key("alt") }
      it { expect(@link_to_image).to have_key("url") }
      it { expect(@link_to_image).to have_key("is_image") }
      it { expect(@link_to_image).to have_value("banana_sample") }
      it { expect(@link_to_image["is_image"]).to equal(true) }
      it { expect(@link_to_image["url"]).to match("http://test.example/uploads/#{@project.path_with_namespace}") }
      it { expect(@link_to_image["url"]).to match("banana_sample.gif") }
    end

     context 'for valid png file' do
      before do
        png = fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')
        @link_to_image = upload_image(@project.repository, { 'markdown_file' => png }, "http://test.example/")
      end

      it { expect(@link_to_image).to have_key("alt") }
      it { expect(@link_to_image).to have_key("url") }
      it { expect(@link_to_image).to have_value("dk") }
      it { expect(@link_to_image).to have_key("is_image") }
      it { expect(@link_to_image["is_image"]).to equal(true) }
      it { expect(@link_to_image["url"]).to match("http://test.example/uploads/#{@project.path_with_namespace}") }
      it { expect(@link_to_image["url"]).to match("dk.png") }
    end

     context 'for valid jpg file' do
      before do
        jpg = fixture_file_upload(Rails.root + 'spec/fixtures/rails_sample.jpg', 'image/jpg')
        @link_to_image = upload_image(@project.repository, { 'markdown_file' => jpg }, "http://test.example/")
      end

      it { expect(@link_to_image).to have_key("alt") }
      it { expect(@link_to_image).to have_key("url") }
      it { expect(@link_to_image).to have_key("is_image") }
      it { expect(@link_to_image).to have_value("rails_sample") }
      it { expect(@link_to_image["is_image"]).to equal(true) }
      it { expect(@link_to_image["url"]).to match("http://test.example/uploads/#{@project.path_with_namespace}") }
      it { expect(@link_to_image["url"]).to match("rails_sample.jpg") }
    end

    context 'for txt file' do
      before do
        txt = fixture_file_upload(Rails.root + 'spec/fixtures/doc_sample.txt', 'text/plain')
        @link_to_image = upload_image(@project.repository, { 'markdown_file' => txt }, "http://test.example/")
      end

      it { expect(@link_to_image).to have_key("alt") }
      it { expect(@link_to_image).to have_key("url") }
      it { expect(@link_to_image).to have_key("is_image") }
      it { expect(@link_to_image).to have_value("doc_sample") }
      it { expect(@link_to_image["is_image"]).to equal(false) }
      it { expect(@link_to_image["url"]).to match("http://test.example/uploads/#{@project.path_with_namespace}") }
      it { expect(@link_to_image["url"]).to match("doc_sample.txt") }
    end
  end

  def upload_image(repository, params, root_url)
    Projects::FileService.new(repository, params, root_url).execute
  end
end
