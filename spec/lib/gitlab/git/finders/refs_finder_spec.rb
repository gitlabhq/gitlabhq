# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Git::Finders::RefsFinder, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository }
  let(:finder) { described_class.new(repository, **params) }
  let(:params) { {} }

  describe "#execute" do
    subject { finder.execute }

    context "when :ref_type is :branches" do
      let(:params) do
        { search: "mast", ref_type: :branches }
      end

      it { is_expected.to be_an(Array) }

      it "returns matching ref object" do
        expect(subject.length).to eq(1)

        ref = subject.first

        expect(ref).to be_a(Gitaly::ListRefsResponse::Reference)
        expect(ref.name).to eq("refs/heads/master")
        expect(ref.target).to be_a(String)
      end
    end

    context "when :ref_type is :tags" do
      let(:params) do
        { search: "v1.0.", ref_type: :tags }
      end

      it { is_expected.to be_an(Array) }

      it "returns matching ref object" do
        expect(subject.length).to eq(1)

        ref = subject.first

        expect(ref).to be_a(Gitaly::ListRefsResponse::Reference)
        expect(ref.name).to eq("refs/tags/v1.0.0")
        expect(ref.target).to be_a(String)
      end
    end

    context "when :ref_type is invalid" do
      let(:params) do
        { search: "master", ref_type: nil }
      end

      it "raises an error" do
        expect { subject }.to raise_error(described_class::UnknownRefTypeError)
      end
    end

    describe 'Search' do
      context 'when searching by postfix' do
        let(:params) do
          { search: "aster", ref_type: :branches }
        end

        it "returns matching ref object" do
          expect(subject.length).to eq(1)

          expect(subject.first.name).to eq("refs/heads/master")
        end
      end

      context 'when searching by scoped branch' do
        let(:params) do
          { search: "awesome", ref_type: :branches }
        end

        it "returns matching ref object" do
          expect(subject.length).to eq(1)

          expect(subject.first.name).to eq("refs/heads/improve/awesome")
        end

        context 'when mixed part is provided' do
          let(:params) do
            { search: "prove/awe", ref_type: :branches }
          end

          it "returns matching ref object" do
            expect(subject.length).to eq(1)

            expect(subject.first.name).to eq("refs/heads/improve/awesome")
          end
        end

        context 'when branch has deeply nested name' do
          before do
            project.repository.create_branch('some/branch/deep')
          end

          after do
            project.repository.delete_branch('some/branch/deep')
          end

          let(:params) do
            { search: "deep", ref_type: :branches }
          end

          it "returns matching ref object" do
            expect(subject.length).to eq(1)

            expect(subject.first.name).to eq("refs/heads/some/branch/deep")
          end
        end
      end
    end

    describe 'Sort' do
      context 'without sort' do
        let(:params) do
          { ref_type: :tags }
        end

        it "returns refs sorted by name in ascending order" do
          refs = subject

          expect(refs.map(&:name)).to eq(['refs/tags/v1.0.0', 'refs/tags/v1.1.0', 'refs/tags/v1.1.1'])
        end
      end

      context 'with sort by name in descending order' do
        let(:params) do
          { ref_type: :tags, sort_by: 'name_desc' }
        end

        it "returns refs sorted by name in descending order" do
          refs = subject

          expect(refs.map(&:name)).to eq(['refs/tags/v1.1.1', 'refs/tags/v1.1.0', 'refs/tags/v1.0.0'])
        end
      end

      context 'with sort by updated in descending order' do
        let(:params) do
          { ref_type: :tags, sort_by: 'updated_desc' }
        end

        it "returns refs sorted by created timestamp in descending order" do
          refs = subject

          expect(refs.map(&:name)).to eq(['refs/tags/v1.1.1', 'refs/tags/v1.1.0', 'refs/tags/v1.0.0'])
        end
      end
    end

    describe 'Pagination' do
      context 'with per page limit' do
        let(:params) do
          { ref_type: :tags, per_page: 2 }
        end

        it "returns limited results" do
          refs = subject

          expect(refs.length).to eq(2)
          expect(refs.map(&:name)).to match_array(["refs/tags/v1.0.0", "refs/tags/v1.1.0"])
        end
      end

      context 'with per page limit and token' do
        let(:params) do
          { ref_type: :tags, per_page: 2, page_token: 'refs/tags/v1.1.0' }
        end

        it "returns next page of limited results" do
          refs = subject

          expect(refs.length).to eq(1)
          expect(refs.map(&:name)).to match_array(["refs/tags/v1.1.1"])
        end
      end

      context 'with only page token' do
        let(:params) do
          { ref_type: :tags, page_token: 'refs/tags/v1.1.0' }
        end

        it "returns all records" do
          refs = subject

          expect(refs.length).to eq(3)
          expect(refs.map(&:name)).to match_array(['refs/tags/v1.0.0', 'refs/tags/v1.1.0', 'refs/tags/v1.1.1'])
        end
      end

      context 'with invalid token' do
        let(:params) do
          { ref_type: :tags, per_page: 2, page_token: 'wrong' }
        end

        it { expect { subject }.to raise_error(Gitlab::Git::InvalidPageToken) }
      end

      context 'with unknown argument error' do
        let(:params) { { ref_type: :tags } }
        let(:argument_error) { ArgumentError.new('unknown error') }

        before do
          allow(repository).to receive(:list_refs).and_raise(argument_error)
        end

        it { expect { subject }.to raise_error(argument_error) }
      end

      context 'with invalid per_page' do
        let(:params) do
          { ref_type: :tags, per_page: -2 }
        end

        it "returns all results" do
          refs = subject

          expect(refs.length).to eq(3)
        end
      end
    end
  end
end
