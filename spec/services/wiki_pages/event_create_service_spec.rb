# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::EventCreateService, feature_category: :wiki do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  describe '#execute' do
    let_it_be(:page) { create(:wiki_page, project: project) }

    let(:action) { :created }
    let(:fingerprint) { page.sha }
    let(:wiki_page_meta) { create(:wiki_page_meta) }
    let(:response) { subject.execute(wiki_page_meta, action, fingerprint) }

    context 'the user is nil' do
      subject { described_class.new(nil) }

      it 'raises an error on construction' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'the action is illegal' do
      let(:action) { :illegal_action }

      it 'returns an error' do
        expect(response).to be_error
      end

      it 'does not create an event' do
        expect { response }.not_to change(Event, :count)
      end
    end

    it 'returns a successful response' do
      expect(response).to be_success
    end

    it 'creates a wiki page event' do
      expect { response }.to change(Event, :count).by(1)
    end

    it 'returns an event in the payload' do
      expect(response.payload).to include(event: have_attributes(author: user, wiki_page?: true, action: 'created'))
    end
  end
end
