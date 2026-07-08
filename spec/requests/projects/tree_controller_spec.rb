# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects tree controller', feature_category: :source_code_management do
  describe 'GET show for an ambiguous branch and tag whose names embed a ref prefix' do
    def get_show(ref_type:)
      get project_tree_path(ambiguous_project, ambiguous_ref, ref_type: ref_type)
    end

    context 'with a branch named "refs/tags/release" alongside a tag "release"' do
      include_context 'with an ambiguous branch and tag fixture',
        branch_name: 'refs/tags/release', tag_name: 'release'

      let(:ambiguous_ref) { 'refs/tags/release' }

      it_behaves_like 'an ambiguous ref with divergent branch and tag content'
      it_behaves_like 'archive download links anchored to the ref_type', ref_type: 'heads'
      it_behaves_like 'archive download links not anchored to a ref_type'
    end

    context 'with a tag named "refs/heads/release" alongside a branch "release"' do
      include_context 'with an ambiguous branch and tag fixture',
        branch_name: 'release', tag_name: 'refs/heads/release'

      let(:ambiguous_ref) { 'refs/heads/release' }

      it_behaves_like 'an ambiguous ref with divergent branch and tag content'
      it_behaves_like 'archive download links anchored to the ref_type', ref_type: 'tags'
      it_behaves_like 'archive download links not anchored to a ref_type'
    end
  end
end
