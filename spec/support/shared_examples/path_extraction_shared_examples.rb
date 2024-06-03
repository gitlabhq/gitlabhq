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
    let(:ref) { '38008cb17ce1466d8fec2dfa6f6ab8dcfe5cf49e' }
    let(:path) { 'with space' }

    it 'is not converted to %20 in @path' do
      assign_ref_vars

      expect(@path).to eq(path)
    end
  end
end
