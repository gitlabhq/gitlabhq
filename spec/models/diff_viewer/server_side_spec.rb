# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffViewer::ServerSide do
  let_it_be(:project) { create(:project, :repository) }

  let(:commit) { project.commit_by(oid: '570e7b2abdd848b95f2f578043fc23bd6f6fd24d') }
  let!(:diff_file) { commit.diffs.diff_file_with_new_path('files/ruby/popen.rb') }

  let(:viewer_class) do
    Class.new(DiffViewer::Base) do
      include DiffViewer::ServerSide
    end
  end

  subject { viewer_class.new(diff_file) }

  describe '#prepare!' do
    it 'loads all diff file data' do
      expect(Blob).to receive(:lazy).at_least(:twice)

      subject.prepare!
    end
  end

  describe '#render_error' do
    context 'when the diff file is stored externally' do
      before do
        allow(diff_file).to receive(:stored_externally?).and_return(true)
      end

      it 'return :server_side_but_stored_externally' do
        expect(subject.render_error).to eq(:server_side_but_stored_externally)
      end
    end
  end

  describe '#render_error_reason' do
    context 'when the diff file is stored externally' do
      before do
        allow(diff_file).to receive(:stored_externally?).and_return(true)
      end

      it 'returns error message if stored in LFS' do
        allow(diff_file).to receive(:external_storage).and_return(:lfs)

        expect(subject.render_error_message).to include('it is stored in LFS')
      end

      it 'returns error message if stored externally' do
        allow(diff_file).to receive(:external_storage).and_return(:foo)

        expect(subject.render_error_message).to include('it is stored externally')
      end
    end
  end
end
