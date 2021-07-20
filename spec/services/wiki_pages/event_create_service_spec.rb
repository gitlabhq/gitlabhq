# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::EventCreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user) }

  describe '#execute' do
    let_it_be(:page) { create(:wiki_page, project: project) }

    let(:slug) { generate(:sluggified_title) }
    let(:action) { :created }
    let(:fingerprint) { page.sha }
    let(:response) { subject.execute(slug, page, action, fingerprint) }

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

      it 'does not create a metadata record' do
        expect { response }.not_to change(WikiPage::Meta, :count)
      end
    end

    it 'returns a successful response' do
      expect(response).to be_success
    end

    context 'the action is a deletion' do
      let(:action) { :destroyed }

      it 'does not synchronize the wiki metadata timestamps with the git commit' do
        expect_next_instance_of(WikiPage::Meta) do |instance|
          expect(instance).not_to receive(:synch_times_with_page)
        end

        response
      end
    end

    it 'creates a wiki page event' do
      expect { response }.to change(Event, :count).by(1)
    end

    it 'returns an event in the payload' do
      expect(response.payload).to include(event: have_attributes(author: user, wiki_page?: true, action: 'created'))
    end

    it 'records the slug for the page' do
      response
      meta = WikiPage::Meta.find_or_create(page.slug, page)

      expect(meta.slugs.pluck(:slug)).to include(slug)
    end
  end
end
