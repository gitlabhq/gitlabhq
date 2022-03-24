# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Blame do
  let(:project) { create(:project, :repository) }
  let(:path) { 'files/ruby/popen.rb' }
  let(:commit) { project.commit('master') }
  let(:blob) { project.repository.blob_at(commit.id, path) }

  describe "#groups" do
    let(:subject) { described_class.new(blob, commit).groups(highlight: false) }

    it 'groups lines properly' do
      expect(subject.count).to eq(18)
      expect(subject[0][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
      expect(subject[0][:lines]).to eq(["require 'fileutils'", "require 'open3'", ""])

      expect(subject[1][:commit].sha).to eq('874797c3a73b60d2187ed6e2fcabd289ff75171e')
      expect(subject[1][:lines]).to eq(["module Popen", "  extend self"])

      expect(subject[-1][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
      expect(subject[-1][:lines]).to eq(["  end", "end"])
    end

    context 'renamed file' do
      let(:path) { 'files/plain_text/renamed' }
      let(:commit) { project.commit('blame-on-renamed') }

      it 'adds previous path' do
        expect(subject[0][:previous_path]).to be nil
        expect(subject[0][:lines]).to match_array(['Initial commit', 'Initial commit'])

        expect(subject[1][:previous_path]).to eq('files/plain_text/initial-commit')
        expect(subject[1][:lines]).to match_array(['Renamed as "filename"'])
      end
    end
  end
end
