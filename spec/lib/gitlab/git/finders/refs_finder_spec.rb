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
  end
end
