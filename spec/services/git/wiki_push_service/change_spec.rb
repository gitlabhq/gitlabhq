# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Git::WikiPushService::Change, feature_category: :source_code_management do
  subject { described_class.new(project_wiki, change, raw_change) }

  let(:project_wiki) { double('ProjectWiki') }
  let(:raw_change) { double('RawChange', new_path: new_path, old_path: old_path, operation: operation) }
  let(:change) { { oldrev: generate(:sha), newrev: generate(:sha) } }

  let(:new_path) do
    case operation
    when :deleted
      nil
    else
      generate(:wiki_filename)
    end
  end

  let(:old_path) do
    case operation
    when :added
      nil
    when :deleted, :renamed
      generate(:wiki_filename)
    else
      new_path
    end
  end

  describe '#page' do
    context 'the page does not exist' do
      before do
        expect(project_wiki).to receive(:find_page).with(String, String).and_return(nil)
      end

      %i[added deleted renamed modified].each do |op|
        context "the operation is #{op}" do
          let(:operation) { op }

          it { is_expected.to have_attributes(page: be_nil) }
        end
      end
    end

    context 'the page can be found' do
      let(:wiki_page) { double('WikiPage') }

      before do
        expect(project_wiki).to receive(:find_page).with(slug, revision).and_return(wiki_page)
      end

      context 'the page has been deleted' do
        let(:operation) { :deleted }
        let(:slug) { old_path.chomp('.md') }
        let(:revision) { change[:oldrev] }

        it { is_expected.to have_attributes(page: wiki_page) }
      end

      %i[added renamed modified].each do |op|
        context "the operation is #{op}" do
          let(:operation) { op }
          let(:slug) { new_path.chomp('.md') }
          let(:revision) { change[:newrev] }

          it { is_expected.to have_attributes(page: wiki_page) }
        end
      end
    end
  end

  describe '#last_known_slug' do
    context 'the page has been created' do
      let(:operation) { :added }

      it { is_expected.to have_attributes(last_known_slug: new_path.chomp('.md')) }
    end

    %i[renamed modified deleted].each do |op|
      context "the operation is #{op}" do
        let(:operation) { op }

        it { is_expected.to have_attributes(last_known_slug: old_path.chomp('.md')) }
      end
    end
  end

  describe '#event_action' do
    context 'the page is deleted' do
      let(:operation) { :deleted }

      it { is_expected.to have_attributes(event_action: :destroyed) }
    end

    context 'the page is added' do
      let(:operation) { :added }

      it { is_expected.to have_attributes(event_action: :created) }
    end

    %i[renamed modified].each do |op|
      context "the page is #{op}" do
        let(:operation) { op }

        it { is_expected.to have_attributes(event_action: :updated) }
      end
    end
  end
end
