# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/gitlab/event_store_doc_required'

RSpec.describe RuboCop::Cop::Gitlab::EventStoreDocRequired, feature_category: :tooling do
  let(:rails_root) { File.expand_path('../../../..', __dir__) }
  let(:doc_path) { File.join(rails_root, 'data/events/foo/bar_event.yml') }
  let(:event_class_source) do
    <<~RUBY
      module Foo
        class BarEvent < Gitlab::EventStore::Event
        end
      end
    RUBY
  end

  before do
    allow(cop).to receive(:source_path).and_return(source_path)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(doc_path).and_return(doc_exists)
    allow(YAML).to receive(:safe_load_file).with(doc_path).and_return(doc_contents) if doc_exists
  end

  def offense_messages(source)
    inspect_source(source).map(&:message)
  end

  shared_examples 'requires a documentation file' do
    context 'when no documentation file exists' do
      let(:doc_exists) { false }
      let(:doc_contents) { nil }

      it 'registers an offense' do
        expect(offense_messages(event_class_source)).to contain_exactly(
          a_string_matching(%r{Add event documentation at `data/events/foo/bar_event\.yml`})
        )
      end
    end
  end

  context 'with a CE event' do
    let(:source_path) { File.join(rails_root, 'app/events/foo/bar_event.rb') }

    it_behaves_like 'requires a documentation file'

    context 'when documentation declares ee_only: true' do
      let(:doc_exists) { true }
      let(:doc_contents) { { 'ee_only' => true } }

      it 'registers an offense' do
        expect(offense_messages(event_class_source)).to contain_exactly(
          a_string_matching(%r{Event class is under `app/events/` but .* declares `ee_only: true`})
        )
      end
    end

    context 'when documentation omits ee_only' do
      let(:doc_exists) { true }
      let(:doc_contents) { {} }

      it 'does not register an offense' do
        expect(offense_messages(event_class_source)).to be_empty
      end
    end

    context 'when documentation declares ee_only: false' do
      let(:doc_exists) { true }
      let(:doc_contents) { { 'ee_only' => false } }

      it 'does not register an offense' do
        expect(offense_messages(event_class_source)).to be_empty
      end
    end
  end

  context 'with an EE event' do
    let(:source_path) { File.join(rails_root, 'ee/app/events/foo/bar_event.rb') }

    it_behaves_like 'requires a documentation file'

    context 'when documentation omits ee_only' do
      let(:doc_exists) { true }
      let(:doc_contents) { {} }

      it 'registers an offense' do
        expect(offense_messages(event_class_source)).to contain_exactly(
          a_string_matching(%r{Event class is under `ee/app/events/` but .* does not declare `ee_only: true`})
        )
      end
    end

    context 'when documentation declares ee_only: false' do
      let(:doc_exists) { true }
      let(:doc_contents) { { 'ee_only' => false } }

      it 'registers an offense' do
        expect(offense_messages(event_class_source)).to contain_exactly(
          a_string_matching(/does not declare `ee_only: true`/)
        )
      end
    end

    context 'when documentation declares ee_only: true' do
      let(:doc_exists) { true }
      let(:doc_contents) { { 'ee_only' => true } }

      it 'does not register an offense' do
        expect(offense_messages(event_class_source)).to be_empty
      end
    end
  end

  describe '#external_dependency_checksum' do
    let(:source_path) { File.join(rails_root, 'app/events/foo/bar_event.rb') }
    let(:doc_exists) { false }
    let(:doc_contents) { nil }

    it 'returns a SHA256 digest used by RuboCop to invalidate cache' do
      expect(cop.external_dependency_checksum).to match(/^\h{64}$/)
    end
  end

  context 'with a class that does not inherit from Gitlab::EventStore::Event' do
    let(:source_path) { File.join(rails_root, 'app/events/foo/bar_event.rb') }
    let(:doc_exists) { false }
    let(:doc_contents) { nil }

    it 'does not register an offense' do
      source = <<~RUBY
        module Foo
          class BarEvent < ApplicationRecord
          end
        end
      RUBY

      expect(offense_messages(source)).to be_empty
    end
  end
end
