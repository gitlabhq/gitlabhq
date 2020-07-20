# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SafeZip::ExtractParams do
  let(:target_path) { Dir.mktmpdir("safe-zip") }
  let(:params) { described_class.new(directories: directories, to: target_path) }
  let(:directories) { %w(public folder/with/subfolder) }

  after do
    FileUtils.remove_entry_secure(target_path)
  end

  describe '#extract_path' do
    subject { params.extract_path }

    it { is_expected.to eq(target_path) }
  end

  describe '#matching_target_directory' do
    using RSpec::Parameterized::TableSyntax

    subject { params.matching_target_directory(target_path + path) }

    where(:path, :result) do
      '/public/index.html' | '/public/'
      '/non/existing/path' | nil
      '/public' | nil
      '/folder/with/index.html' | nil
    end

    with_them do
      it { is_expected.to eq(result ? target_path + result : nil) }
    end
  end

  describe '#target_directories' do
    subject { params.target_directories }

    it 'starts with target_path' do
      is_expected.to all(start_with(target_path + '/'))
    end

    it 'ends with / for all paths' do
      is_expected.to all(end_with('/'))
    end
  end

  describe '#directories_wildcard' do
    subject { params.directories_wildcard }

    it 'adds * for all paths' do
      is_expected.to all(end_with('/*'))
    end
  end
end
