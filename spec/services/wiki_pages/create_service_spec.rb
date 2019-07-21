# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::CreateService do
  let(:project) { create(:project, :wiki_repo) }
  let(:user) { create(:user) }

  let(:opts) do
    {
      title: 'Title',
      content: 'Content for wiki page',
      format: 'markdown'
    }
  end

  let(:bad_opts) do
    { title: '' }
  end

  subject(:service) { described_class.new(project, user, opts) }

  before do
    project.add_developer(user)
  end

  describe '#execute' do
    it 'creates wiki page with valid attributes' do
      page = service.execute

      expect(page).to be_valid
      expect(page.title).to eq(opts[:title])
      expect(page.content).to eq(opts[:content])
      expect(page.format).to eq(opts[:format].to_sym)
    end

    it 'executes webhooks' do
      expect(service).to receive(:execute_hooks).once
        .with(instance_of(WikiPage), 'create')

      service.execute
    end

    it 'counts wiki page creation' do
      counter = Gitlab::UsageDataCounters::WikiPageCounter

      expect { service.execute }.to change { counter.read(:create) }.by 1
    end

    context 'when the options are bad' do
      subject(:service) { described_class.new(project, user, bad_opts) }

      it 'does not count a creation event' do
        counter = Gitlab::UsageDataCounters::WikiPageCounter

        expect { service.execute }.not_to change { counter.read(:create) }
      end

      it 'reports the error' do
        expect(service.execute).to be_invalid
          .and have_attributes(errors: be_present)
      end
    end
  end
end
