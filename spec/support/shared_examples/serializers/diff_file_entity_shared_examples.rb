# frozen_string_literal: true

RSpec.shared_examples 'diff file base entity' do
  it 'exposes essential attributes' do
    expect(subject).to include(
      :content_sha, :submodule, :submodule_link,
      :submodule_tree_url, :old_path_html,
      :new_path_html, :blob, :can_modify_blob,
      :file_hash, :file_path, :old_path, :new_path,
      :viewer, :diff_refs, :stored_externally,
      :external_storage, :renamed_file, :deleted_file,
      :a_mode, :b_mode, :new_file, :file_identifier_hash
    )
  end

  # Converted diff files from GitHub import does not contain blob file
  # and content sha.
  context 'when diff file does not have a blob and content sha' do
    it 'exposes some attributes as nil' do
      allow(diff_file).to receive(:content_sha).and_return(nil)
      allow(diff_file).to receive(:blob).and_return(nil)

      expect(subject[:context_lines_path]).to be_nil
      expect(subject[:view_path]).to be_nil
      expect(subject[:highlighted_diff_lines]).to be_nil
      expect(subject[:can_modify_blob]).to be_nil
    end
  end
end

RSpec.shared_examples 'diff file entity' do
  it_behaves_like 'diff file base entity'

  it 'exposes correct attributes' do
    expect(subject).to include(:added_lines, :removed_lines, :context_lines_path)
  end

  context 'when a viewer' do
    let(:collapsed) { false }
    let(:added_lines) { 1 }
    let(:removed_lines) { 0 }
    let(:highlighted_lines) { nil }

    before do
      allow(diff_file).to receive(:diff_lines_for_serializer)
        .and_return(highlighted_lines)

      allow(diff_file).to receive(:added_lines)
        .and_return(added_lines)

      allow(diff_file).to receive(:removed_lines)
        .and_return(removed_lines)

      allow(diff_file).to receive(:collapsed?)
        .and_return(collapsed)
    end

    it 'matches the schema' do
      expect(subject[:viewer].with_indifferent_access)
        .to match_schema('entities/diff_viewer')
    end

    context 'when it is a whitespace only change' do
      it 'has whitespace_only true' do
        expect(subject[:viewer][:whitespace_only])
          .to eq(true)
      end
    end

    context 'when the highlighted lines arent shown' do
      before do
        allow(diff_file).to receive(:text?)
          .and_return(false)
      end

      it 'has whitespace_only nil' do
        expect(subject[:viewer][:whitespace_only])
          .to eq(nil)
      end
    end

    context 'when it is a new file' do
      let(:added_lines) { 0 }

      it 'has whitespace_only false' do
        expect(subject[:viewer][:whitespace_only])
          .to eq(false)
      end
    end

    context 'when it is a collapsed file' do
      let(:collapsed) { true }

      it 'has whitespace_only false' do
        expect(subject[:viewer][:whitespace_only])
          .to eq(false)
      end
    end
  end

  context 'diff files' do
    context 'when diff_view is parallel' do
      let(:options) { { diff_view: :parallel } }

      it 'contains only the parallel diff lines', :aggregate_failures do
        expect(subject).to include(:parallel_diff_lines)
        expect(subject).not_to include(:highlighted_diff_lines)
      end
    end

    context 'when diff_view is parallel' do
      let(:options) { { diff_view: :inline } }

      it 'contains only the inline diff lines', :aggregate_failures do
        expect(subject).not_to include(:parallel_diff_lines)
        expect(subject).to include(:highlighted_diff_lines)
      end
    end
  end
end

RSpec.shared_examples 'diff file discussion entity' do
  it_behaves_like 'diff file base entity'
end

RSpec.shared_examples 'diff file with conflict_type' do
  describe '#conflict_type' do
    it 'returns nil by default' do
      expect(subject[:conflict_type]).to be_nil
    end

    context 'when there is matching conflict file' do
      let(:renamed_file?) { false }

      let(:options) do
        {
          conflicts: {
            diff_file.new_path => {
              conflict_type: :removed_target_renamed_source,
              conflict_type_when_renamed: :renamed_same_file
            }
          }
        }
      end

      before do
        allow(diff_file)
          .to receive(:renamed_file?)
          .and_return(renamed_file?)
      end

      it 'returns conflict_type' do
        expect(subject[:conflict_type]).to eq(:removed_target_renamed_source)
      end

      context 'when diff file is renamed' do
        let(:renamed_file?) { true }

        it 'returns conflict_type' do
          expect(subject[:conflict_type]).to eq(:renamed_same_file)
        end
      end
    end
  end
end
