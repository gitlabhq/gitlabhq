# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ExternalWiki do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:external_wiki_url) }
      it_behaves_like 'issue tracker integration URL attribute', :external_wiki_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:external_wiki_url) }
    end
  end

  describe 'test' do
    before do
      subject.properties['external_wiki_url'] = url
    end

    let(:url) { 'http://foo' }
    let(:data) { nil }
    let(:result) { subject.test(data) }

    context 'the URL is not reachable' do
      before do
        WebMock.stub_request(:get, url).to_return(status: 404, body: 'not a page')
      end

      it 'is not successful' do
        expect(result[:success]).to be_falsey
      end
    end

    context 'the URL is reachable' do
      before do
        WebMock.stub_request(:get, url).to_return(status: 200, body: 'foo')
      end

      it 'is successful' do
        expect(result[:success]).to be_truthy
      end
    end
  end
end
