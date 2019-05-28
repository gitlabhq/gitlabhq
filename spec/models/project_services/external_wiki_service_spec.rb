# frozen_string_literal: true

require 'spec_helper'

describe ExternalWikiService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:external_wiki_url) }
      it_behaves_like 'issue tracker service URL attribute', :external_wiki_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:external_wiki_url) }
    end
  end
end
