require 'spec_helper'

describe Gitlab::Blame do
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
  end
end
