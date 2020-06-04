# frozen_string_literal: true

RSpec.shared_examples 'assigns ref vars' do
  it 'assigns the repository var' do
    assign_ref_vars

    expect(@repo).to eq container.repository
  end

  context 'ref contains %20' do
    let(:ref) { 'foo%20bar' }

    it 'is not converted to a space in @id' do
      container.repository.add_branch(owner, 'foo%20bar', 'master')

      assign_ref_vars

      expect(@id).to start_with('foo%20bar/')
    end
  end

  context 'ref contains trailing space' do
    let(:ref) { 'master ' }

    it 'strips surrounding space' do
      assign_ref_vars

      expect(@ref).to eq('master')
    end
  end

  context 'ref contains leading space' do
    let(:ref) { ' master ' }

    it 'strips surrounding space' do
      assign_ref_vars

      expect(@ref).to eq('master')
    end
  end

  context 'path contains space' do
    let(:params) { { path: 'with space', ref: '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' } }

    it 'is not converted to %20 in @path' do
      assign_ref_vars

      expect(@path).to eq(params[:path])
    end
  end

  context 'subclass overrides get_id' do
    it 'uses ref returned by get_id' do
      allow_next_instance_of(self.class) do |instance|
        allow(instance).to receive(:get_id) { '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' }
      end

      assign_ref_vars

      expect(@id).to eq(get_id)
    end
  end
end

RSpec.shared_examples 'extracts refs' do
  describe '#extract_ref' do
    it 'returns an empty pair when no repository_container is set' do
      allow_any_instance_of(described_class).to receive(:repository_container).and_return(nil)
      expect(extract_ref('master/CHANGELOG')).to eq(['', ''])
    end

    context 'without a path' do
      it 'extracts a valid branch' do
        expect(extract_ref('master')).to eq(['master', ''])
      end

      it 'extracts a valid tag' do
        expect(extract_ref('v2.0.0')).to eq(['v2.0.0', ''])
      end

      it 'extracts a valid commit ref without a path' do
        expect(extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062')).to eq(
          ['f4b14494ef6abf3d144c28e4af0c20143383e062', '']
        )
      end

      it 'falls back to a primitive split for an invalid ref' do
        expect(extract_ref('stable')).to eq(['stable', ''])
      end

      it 'extracts the longest matching ref' do
        expect(extract_ref('release/app/v1.0.0/README.md')).to eq(
          ['release/app/v1.0.0', 'README.md'])
      end
    end

    context 'with a path' do
      it 'extracts a valid branch' do
        expect(extract_ref('foo/bar/baz/CHANGELOG')).to eq(
          ['foo/bar/baz', 'CHANGELOG'])
      end

      it 'extracts a valid tag' do
        expect(extract_ref('v2.0.0/CHANGELOG')).to eq(['v2.0.0', 'CHANGELOG'])
      end

      it 'extracts a valid commit SHA' do
        expect(extract_ref('f4b14494ef6abf3d144c28e4af0c20143383e062/CHANGELOG')).to eq(
          %w(f4b14494ef6abf3d144c28e4af0c20143383e062 CHANGELOG)
        )
      end

      it 'falls back to a primitive split for an invalid ref' do
        expect(extract_ref('stable/CHANGELOG')).to eq(%w(stable CHANGELOG))
      end
    end
  end
end
