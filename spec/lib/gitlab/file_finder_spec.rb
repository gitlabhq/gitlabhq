# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FileFinder, feature_category: :global_search do
  describe '#find' do
    let_it_be(:project) { create(:project, :public, :repository) }

    subject(:file_finder) { described_class.new(project, project.default_branch) }

    it_behaves_like 'file finder' do
      let(:expected_file_by_path) { 'files/images/wm.svg' }
      let(:expected_file_by_content) { 'CHANGELOG' }
    end

    context 'with inclusive filters' do
      it 'filters by filename and ignores case', :aggregate_failures do
        results = file_finder.find('files filename:wm.svg')
        expect(results.count).to eq(1)

        results = file_finder.find('files filename:Wm.svg')
        expect(results.count).to eq(1)
      end

      it 'filters by path and ignores case', :aggregate_failures do
        results = file_finder.find('white path:images')
        expect(results.count).to eq(2)

        results = file_finder.find('white path:imAGes')
        expect(results.count).to eq(2)
      end

      it 'filters by extension and ignores case', :aggregate_failures do
        results = file_finder.find('files extension:md')
        expect(results.count).to eq(4)

        results = file_finder.find('files extension:MD')
        expect(results.count).to eq(4)
      end
    end

    context 'with exclusive filters' do
      it 'filters by filename' do
        results = file_finder.find('files -filename:wm.svg')

        expect(results.count).to eq(26)
      end

      it 'filters by path' do
        results = file_finder.find('white -path:images')

        expect(results.count).to eq(5)
      end

      it 'filters by extension' do
        results = file_finder.find('files -extension:md')

        expect(results.count).to eq(23)
      end
    end

    context 'with white space in the path' do
      it 'filters by path correctly' do
        results = subject.find('directory path:"with space/README.md"')

        expect(results.count).to eq(1)
      end
    end

    it 'does not cause N+1 query' do
      expect(Gitlab::GitalyClient).to receive(:call).at_most(10).times.and_call_original

      file_finder.find(': filename:wm.svg')
    end

    context 'for protection against ReDOS' do
      # filter is run once for each result returned, searching for `PROCESS.md` returns 2 results
      it 'utilizes ::Gitlab::UntrustedRegexp for filename filter' do
        query = "PROCESS.md filename:P#{'*' * 50}m"
        expected_regex_value = "(?i)p#{'.*?' * 50}m$"
        expect(::Gitlab::UntrustedRegexp).to receive(:new).with(expected_regex_value).twice.and_call_original

        file_finder.find(query)
      end

      it 'utilizes ::Gitlab::UntrustedRegexp for path filter' do
        query = "PROCESS.md path:P#{'*' * 10}m"
        expected_regex_value = "(?i)p#{'.*?' * 10}m"

        expect(::Gitlab::UntrustedRegexp).to receive(:new).with(expected_regex_value).twice.and_call_original
        file_finder.find(query)
      end

      it 'utilizes ::Gitlab::UntrustedRegexp for extension filter' do
        query = "PROCESS.md extension:#{'*' * 10}md"
        expected_regex_value = "(?i)\\.#{'.*?' * 10}md$"

        expect(::Gitlab::UntrustedRegexp).to receive(:new).with(expected_regex_value).twice.and_call_original
        file_finder.find(query)
      end
    end
  end
end
