# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::ServiceDeskUploadLinkFilter, feature_category: :service_desk do
  def filter(doc, contexts = {})
    described_class.call(doc, contexts)
  end

  def link(path, text)
    %(<a href="#{path}">#{text}</a>)
  end

  let(:file_name) { 'test.jpg' }
  let(:secret) { 'e90decf88d8f96fe9e1389afc2e4a91f' }
  let(:upload_path) { "/uploads/#{secret}/#{file_name}" }
  let(:html_link) { link(upload_path, file_name) }

  context 'when replace_upload_links enabled' do
    context 'when it has only one attachment to replace' do
      let(:contexts) { { uploads_as_attachments: ["#{secret}/#{file_name}"] } }

      context 'when filename in text is same as in link' do
        it 'replaces the link with original filename in strong' do
          doc = filter(html_link, contexts)

          expect(doc.at_css('a')).to be_nil
          expect(doc.at_css('strong').text).to eq(file_name)
        end
      end

      context 'when filename in text is not same as in link' do
        let(:filename_in_text) { 'Custom name' }
        let(:html_link) { link(upload_path, filename_in_text) }

        it 'replaces the link with filename in text & original filename, in strong' do
          doc = filter(html_link, contexts)

          expect(doc.at_css('a')).to be_nil
          expect(doc.at_css('strong').text).to eq("#{filename_in_text} (#{file_name})")
        end
      end
    end

    context 'when it has more than one attachment to replace' do
      let(:file_name_1) { 'test1.jpg' }
      let(:secret_1) { '17817c73e368777e6f743392e334fb8a' }
      let(:upload_path_1) { "/uploads/#{secret_1}/#{file_name_1}" }
      let(:html_link_1) { link(upload_path_1, file_name_1) }

      context 'when all of uploads can be replaced' do
        let(:contexts) { { uploads_as_attachments: ["#{secret}/#{file_name}", "#{secret_1}/#{file_name_1}"] } }

        it 'replaces all links with original filename in strong' do
          doc = filter("#{html_link} #{html_link_1}", contexts)

          expect(doc.at_css('a')).to be_nil
          expect(doc.at_css("strong:contains('#{file_name}')")).not_to be_nil
          expect(doc.at_css("strong:contains('#{file_name_1}')")).not_to be_nil
        end
      end

      context 'when not all of uploads can be replaced' do
        let(:contexts) { { uploads_as_attachments: ["#{secret}/#{file_name}"] } }

        it 'replaces only specific links with original filename in strong' do
          doc = filter("#{html_link} #{html_link_1}", contexts)

          expect(doc.at_css("strong:contains('#{file_name}')")).not_to be_nil
          expect(doc.at_css("a:contains('#{file_name_1}')")).not_to be_nil
        end
      end
    end
  end

  context 'when uploads_as_attachments is empty' do
    let(:contexts) { { uploads_as_attachments: [] } }

    it 'does not replaces the link' do
      doc = filter(html_link, contexts)

      expect(doc.at_css('a')).not_to be_nil
      expect(doc.at_css('a')['href']).to eq upload_path
    end
  end

  it_behaves_like 'pipeline timing check'
end
