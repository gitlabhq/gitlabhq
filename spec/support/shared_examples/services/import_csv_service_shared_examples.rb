# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples_for 'importer with email notification' do
  it 'notifies user of import result' do
    expect(Notify).to receive_message_chain(email_method, :deliver_later)

    subject
  end
end

RSpec.shared_examples 'correctly handles invalid files' do
  shared_examples_for 'invalid file' do
    it 'returns invalid file error' do
      expect(subject[:success]).to eq(0)
      expect(subject[:parse_error]).to eq(true)
    end
  end

  context 'when given file with unsupported extension' do
    let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }

    it_behaves_like 'invalid file'
  end

  context 'when given empty file' do
    let(:file) { fixture_file_upload('spec/fixtures/csv_empty.csv') }

    it_behaves_like 'invalid file'
  end

  context 'when given file without headers' do
    let(:file) { fixture_file_upload('spec/fixtures/csv_no_headers.csv') }

    it_behaves_like 'invalid file'
  end
end

RSpec.shared_examples 'performs a spam check' do |perform_check|
  it 'initializes issue create service with expected spam check parameter' do
    expect(Issues::CreateService)
      .to receive(:new)
      .at_least(:once)
      .with(hash_including(perform_spam_check: perform_check))
      .and_call_original

    subject
  end
end
