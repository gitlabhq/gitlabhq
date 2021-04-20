# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::Presenters::IssueComment do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:note) { create(:note, project: project, noteable: issue) }

  let(:author) { note.author }

  describe '#present' do
    let(:attachment) { subject[:attachments].first }

    subject { described_class.new(note).present }

    it { is_expected.to be_a(Hash) }

    it 'sets ephemeral response type' do
      expect(subject[:response_type]).to be(:ephemeral)
    end

    it 'sets the title' do
      expect(attachment[:title]).to eq("#{issue.title} · #{issue.to_reference}")
    end

    it 'sets the fallback text' do
      expect(attachment[:fallback]).to eq("New comment on #{issue.to_reference}: #{issue.title}")
    end

    it 'sets the fields' do
      expect(attachment[:fields]).to eq([{ title: 'Comment', value: note.note }])
    end

    it 'sets the color' do
      expect(attachment[:color]).to eq('#38ae67')
    end
  end
end
