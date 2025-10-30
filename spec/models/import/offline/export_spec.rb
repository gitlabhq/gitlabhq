# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Export, feature_category: :importers do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:organization) }
    it { is_expected.to have_many(:bulk_import_exports).class_name('BulkImports::Export') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:source_hostname) }
    it { is_expected.to validate_presence_of(:status) }

    describe '#source_hostname' do
      it { is_expected.to allow_value('http://example.com:8080').for(:source_hostname) }
      it { is_expected.to allow_value('https://example.com:8080').for(:source_hostname) }
      it { is_expected.to allow_value('http://example.com').for(:source_hostname) }
      it { is_expected.to allow_value('https://example.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('http://').for(:source_hostname) }
      it { is_expected.not_to allow_value('example.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com/dir').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com?param=1').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://example.com/dir?param=1').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://github.com').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://bitbucket.org').for(:source_hostname) }
      it { is_expected.not_to allow_value('https://gitea.com').for(:source_hostname) }
    end
  end
end
