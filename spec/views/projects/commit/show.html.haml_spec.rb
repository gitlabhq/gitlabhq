# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commit/show.html.haml', feature_category: :source_code_management do
  let_it_be_with_refind(:project) { create(:project, :repository, :in_group) }

  let(:commit) { project.commit }

  before do
    assign(:project, project)
    assign(:repository, project.repository)
    assign(:commit, commit)
    assign(:noteable, commit)
    assign(:notes, [])
    assign(:diffs, commit.diffs)

    controller.params[:controller] = 'projects/commit'
    controller.params[:action] = 'show'
    controller.params[:namespace_id] = project.namespace.to_param
    controller.params[:project_id] = project.to_param
    controller.params[:id] = commit.id

    allow(view).to receive(:current_user).and_return(nil)
    allow(view).to receive(:can?).and_return(false)
    allow(view).to receive(:can_collaborate_with_project?).and_return(false)
    allow(view).to receive(:current_ref).and_return(project.repository.root_ref)
    allow(view).to receive(:diff_btn).and_return('')
    allow(view).to receive(:pagination_params).and_return({})
  end

  context 'parallel diff view' do
    before do
      allow(view).to receive(:diff_view).and_return(:parallel)
      allow(view).to receive(:fluid_layout).and_return(true)

      render
    end

    it 'spans full width' do
      expect(rendered).not_to have_selector('.limit-container-width')
    end
  end

  context 'in the context of a merge request' do
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    before do
      assign(:merge_request, merge_request)
      render
    end

    it 'shows that it is in the context of a merge request' do
      merge_request_url = diffs_project_merge_request_path(project, merge_request, commit_id: commit.id)
      expect(rendered).to have_content("This commit is part of merge request")
      expect(rendered).to have_link(merge_request.to_reference, href: merge_request_url)
    end

    context 'when merge request is nil' do
      let(:merge_request) { nil }

      it 'renders the page' do
        expect { rendered }.not_to raise_error
      end
    end
  end

  context 'when commit is signed' do
    let(:page) { Nokogiri::HTML.parse(rendered) }
    let(:badge) { page.at('.signature-badge') }
    let(:badge_attributes) { badge.attributes }
    let(:title) { badge_attributes['data-title'].value }
    let(:content) { badge_attributes['data-content'].value }

    context 'with GPG' do
      let(:commit) { project.commit(GpgHelpers::SIGNED_COMMIT_SHA) }

      it 'renders unverified badge' do
        render

        expect(title).to include('This commit was signed with an unverified signature.')
        expect(content).to include(commit.signature.gpg_key_primary_keyid)
      end
    end

    context 'with SSH' do
      let(:commit) { project.commit('7b5160f9bb23a3d58a0accdbe89da13b96b1ece9') }

      it 'renders unverified badge' do
        render

        expect(title).to include('This commit was signed with an unverified signature.')
        expect(content).to match(/SSH key fingerprint:[\s\S].+#{commit.signature.key_fingerprint_sha256}/)
      end

      context 'when the commit has been signed by GitLab' do
        it 'renders verified badge' do
          allow_next_instance_of(Gitlab::Ssh::Commit) do |instance|
            allow(instance).to receive(:signer).and_return(:SIGNER_SYSTEM)
          end

          render

          expect(content).to match(/SSH key fingerprint:[\s\S].+#{commit.signature.key_fingerprint_sha256}/)
          expect(title).to include(
            'This commit was created in the GitLab UI, and signed with a GitLab-verified signature.'
          )
        end
      end
    end

    context 'with X.509' do
      let(:commit) { project.commit('189a6c924013fc3fe40d6f1ec1dc20214183bc97') }

      it 'renders unverified badge' do
        render

        expect(title).to include('This commit was signed with an <strong>unverified</strong> signature.')
        expect(content).to include(commit.signature.x509_certificate.subject_key_identifier.tr(":", " "))
      end
    end
  end
end
