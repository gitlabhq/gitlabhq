# frozen_string_literal: true

RSpec.shared_examples 'extracts ref vars' do
  describe '#extract!' do
    context 'when ref contains %20' do
      let(:ref) { 'foo%20bar' }

      it 'is not converted to a space in @id' do
        container.repository.add_branch(owner, 'foo%20bar', 'master')

        ref_extractor.extract!

        expect(ref_extractor.id).to start_with('foo%20bar/')
      end
    end

    context 'when ref contains trailing space' do
      let(:ref) { 'master ' }

      it 'strips surrounding space' do
        ref_extractor.extract!

        expect(ref_extractor.ref).to eq('master')
      end
    end

    context 'when ref contains leading space' do
      let(:ref) { ' master ' }

      it 'strips surrounding space' do
        ref_extractor.extract!

        expect(ref_extractor.ref).to eq('master')
      end
    end

    context 'when path contains space' do
      let(:ref) { '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' }
      let(:path) { 'with space' }

      it 'is not converted to %20 in @path' do
        ref_extractor.extract!

        expect(ref_extractor.path).to eq(path)
      end
    end

    context 'when override_id is given' do
      let(:ref_extractor) do
        described_class.new(container, params, override_id: '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e')
      end

      it 'uses override_id' do
        ref_extractor.extract!

        expect(ref_extractor.id).to eq('38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e')
      end
    end
  end
end

RSpec.shared_examples 'extracts ref method' do
  describe '#extract_ref' do
    it 'returns an empty pair when no repository_container is set' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:repository_container).and_return(nil)
      end
      expect(ref_extractor.extract_ref('master/CHANGELOG')).to eq(['', ''])
    end

    context 'without a path' do
      it 'extracts a valid branch' do
        expect(ref_extractor.extract_ref('master')).to eq(['master', ''])
      end

      it 'extracts a valid tag' do
        expect(ref_extractor.extract_ref('v2.0.0')).to eq(['v2.0.0', ''])
      end

      it 'extracts a valid commit SHA1 ref without a path' do
        expect(ref_extractor.extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062')).to eq(
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', '']
        )
      end

      it 'extracts a valid commit SHA256 ref without a path' do
        expect(ref_extractor.extract_ref('34627760127d5ff2a644771225af09bbd79f28a54a0a4c03c1881bf2c26dc13c')).to eq(
          ['34627760127d5ff2a644771225af09bbd79f28a54a0a4c03c1881bf2c26dc13c', '']
        )
      end

      it 'falls back to a primitive split for an invalid ref' do
        expect(ref_extractor.extract_ref('stable')).to eq(['stable', ''])
      end

      it 'does not fetch ref names when there is no slash' do
        expect(ref_extractor).not_to receive(:ref_names)

        ref_extractor.extract_ref('master')
      end

      it 'fetches ref names when there is a slash' do
        expect(ref_extractor).to receive(:ref_names).and_call_original

        ref_extractor.extract_ref('release/app/v1.0.0')
      end
    end

    context 'with a path' do
      it 'extracts a valid branch' do
        expect(ref_extractor.extract_ref('foo/bar/baz/CHANGELOG')).to eq(
          ['foo/bar/baz', 'CHANGELOG'])
      end

      it 'extracts a valid tag' do
        expect(ref_extractor.extract_ref('v2.0.0/CHANGELOG')).to eq(['v2.0.0', 'CHANGELOG'])
      end

      it 'extracts a valid commit SHA' do
        expect(ref_extractor.extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG')).to eq(
          %w[f4b14494ef6abf3d144c28e4af0c20143383e062 CHANGELOG]
        )
      end

      it 'falls back to a primitive split for an invalid ref' do
        expect(ref_extractor.extract_ref('stable/CHANGELOG')).to eq(%w[stable CHANGELOG])
      end

      it 'extracts the longest matching ref' do
        expect(ref_extractor.extract_ref('release/app/v1.0.0/README.md')).to eq(
          ['release/app/v1.0.0', 'README.md'])
      end

      context 'when the repository does not have ambiguous refs' do
        before do
          allow(container.repository).to receive(:has_ambiguous_refs?).and_return(false)
        end

        it 'does not fetch all ref names when the first path component is a ref' do
          expect(ref_extractor).not_to receive(:ref_names)
          expect(container.repository).to receive(:branch_names_include?).with('v1.0.0').and_return(false)
          expect(container.repository).to receive(:tag_names_include?).with('v1.0.0').and_return(true)

          expect(ref_extractor.extract_ref('v1.0.0/doc/README.md')).to eq(['v1.0.0', 'doc/README.md'])
        end

        it 'fetches all ref names when the first path component is not a ref' do
          expect(ref_extractor).to receive(:ref_names).and_call_original
          expect(container.repository).to receive(:branch_names_include?).with('release').and_return(false)
          expect(container.repository).to receive(:tag_names_include?).with('release').and_return(false)

          expect(ref_extractor.extract_ref('release/app/doc/README.md')).to eq(['release/app', 'doc/README.md'])
        end
      end

      context 'when the repository has ambiguous refs' do
        before do
          allow(container.repository).to receive(:has_ambiguous_refs?).and_return(true)
        end

        it 'always fetches all ref names' do
          expect(ref_extractor).to receive(:ref_names).and_call_original
          expect(container.repository).not_to receive(:branch_names_include?)
          expect(container.repository).not_to receive(:tag_names_include?)

          expect(ref_extractor.extract_ref('v1.0.0/doc/README.md')).to eq(['v1.0.0', 'doc/README.md'])
        end
      end
    end
  end
end
