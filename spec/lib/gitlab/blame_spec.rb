# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Blame do
  let_it_be(:project) { create(:project, :repository) }

  let(:path) { 'files/ruby/popen.rb' }
  let(:commit) { project.commit('master') }
  let(:blob) { project.repository.blob_at(commit.id, path) }
  let(:range) { nil }

  subject(:blame) { described_class.new(blob, commit, range: range) }

  describe '#first_line' do
    subject { blame.first_line }

    it { is_expected.to eq(1) }

    context 'with a range' do
      let(:range) { 2..3 }

      it { is_expected.to eq(range.first) }
    end
  end

  describe "#groups" do
    let(:highlighted) { false }

    subject(:groups) { blame.groups(highlight: highlighted) }

    it 'groups lines properly' do
      expect(subject.count).to eq(18)
      expect(subject[0][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
      expect(subject[0][:lines]).to eq(["require 'fileutils'", "require 'open3'", ""])
      expect(subject[0][:span]).to eq(3)
      expect(subject[0][:lineno]).to eq(1)

      expect(subject[1][:commit].sha).to eq('874797c3a73b60d2187ed6e2fcabd289ff75171e')
      expect(subject[1][:lines]).to eq(["module Popen", "  extend self"])
      expect(subject[1][:span]).to eq(2)
      expect(subject[1][:lineno]).to eq(4)

      expect(subject[-1][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
      expect(subject[-1][:lines]).to eq(["  end", "end"])
      expect(subject[-1][:span]).to eq(2)
      expect(subject[-1][:lineno]).to eq(36)
    end

    context 'with a range 1..5' do
      let(:range) { 1..5 }

      it 'returns the correct lines' do
        expect(groups.count).to eq(2)
        expect(groups[0][:lines]).to eq(["require 'fileutils'", "require 'open3'", ""])
        expect(groups[1][:lines]).to eq(['module Popen', '  extend self'])
      end

      context 'with highlighted lines' do
        let(:highlighted) { true }

        it 'returns the correct lines' do
          expect(groups.count).to eq(2)
          expect(groups[0][:lines][0]).to match(/LC1.*fileutils/)
          expect(groups[0][:lines][1]).to match(/LC2.*open3/)
          expect(groups[0][:lines][2]).to eq("<span id=\"LC3\" class=\"line\" lang=\"ruby\"></span>\n")
          expect(groups[1][:lines][0]).to match(/LC4.*Popen/)
          expect(groups[1][:lines][1]).to match(/LC5.*extend/)
        end

        context 'when highlighed lines are misaligned' do
          let(:raw_blob) { Gitlab::Git::Blob.new(data: "Test\r\nopen3", path: path, size: 6) }
          let(:blob) { Blob.new(raw_blob) }

          it 'returns the correct lines' do
            expect(groups.count).to eq(2)
            expect(groups[0][:lines][0]).to match(/LC1.*Test/)
            expect(groups[0][:lines][1]).to match(/LC2.*open3/)
          end
        end
      end
    end

    context 'with a range 2..4' do
      let(:range) { 2..4 }

      it 'returns the correct lines' do
        expect(groups.count).to eq(2)
        expect(groups[0][:lines]).to eq(["require 'open3'", ""])
        expect(groups[1][:lines]).to eq(['module Popen'])
      end

      context 'with highlighted lines' do
        let(:highlighted) { true }

        it 'returns the correct lines' do
          expect(groups.count).to eq(2)
          expect(groups[0][:lines][0]).to match(/LC2.*open3/)
          expect(groups[0][:lines][1]).to eq("<span id=\"LC3\" class=\"line\" lang=\"ruby\"></span>\n")
          expect(groups[1][:lines][0]).to match(/LC4.*Popen/)
        end
      end
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
