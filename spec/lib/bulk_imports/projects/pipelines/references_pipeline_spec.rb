# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Pipelines::ReferencesPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:config) { create(:bulk_import_configuration, bulk_import: bulk_import, url: 'https://my.gitlab.com') }
  let_it_be(:entity) do
    create(
      :bulk_import_entity,
      :project_entity,
      project: project,
      bulk_import: bulk_import,
      source_full_path: 'source/full/path'
    )
  end

  let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:issue) { create(:issue, project: project, description: 'https://my.gitlab.com/source/full/path/-/issues/1') }
  let(:mr) do
    create(
      :merge_request,
      source_project: project,
      description: 'https://my.gitlab.com/source/full/path/-/merge_requests/1'
    )
  end

  let(:issue_note) do
    create(
      :note,
      project: project,
      noteable: issue,
      note: 'https://my.gitlab.com/source/full/path/-/issues/1'
    )
  end

  let(:mr_note) do
    create(
      :note,
      project: project,
      noteable: mr,
      note: 'https://my.gitlab.com/source/full/path/-/merge_requests/1'
    )
  end

  let(:old_note_html) { 'old note_html' }
  let(:system_note) do
    create(
      :note,
      project: project,
      system: true,
      noteable: issue,
      note: "mentioned in merge request !#{mr.iid}",
      note_html: old_note_html
    )
  end

  subject(:pipeline) { described_class.new(context) }

  before do
    project.add_owner(user)
  end

  def create_project_data
    [issue, mr, issue_note, mr_note, system_note]
  end

  describe '#extract' do
    it 'returns ExtractedData containing issues, mrs & their notes' do
      create_project_data

      extracted_data = subject.extract(context)

      expect(extracted_data).to be_instance_of(BulkImports::Pipeline::ExtractedData)
      expect(extracted_data.data).to contain_exactly(issue_note, mr, issue, mr_note)
      expect(system_note.note_html).not_to eq(old_note_html)
      expect(system_note.note_html)
        .to include("class=\"gfm gfm-merge_request\">!#{mr.iid}</a></p>")
        .and include(project.full_path.to_s)
    end

    context 'when object body is nil' do
      let(:issue) { create(:issue, project: project, description: nil) }

      it 'returns ExtractedData not containing the object' do
        extracted_data = subject.extract(context)

        expect(extracted_data.data).to contain_exactly(issue_note, mr, mr_note)
      end
    end
  end

  describe '#transform' do
    it 'updates matching urls with new ones' do
      transformed_mr = subject.transform(context, mr)
      transformed_note = subject.transform(context, mr_note)

      expected_url = URI('')
      expected_url.scheme = ::Gitlab.config.gitlab.https ? 'https' : 'http'
      expected_url.host = ::Gitlab.config.gitlab.host
      expected_url.port = ::Gitlab.config.gitlab.port
      expected_url.path = "/#{project.full_path}/-/merge_requests/#{mr.iid}"

      expect(transformed_mr.description).to eq(expected_url.to_s)
      expect(transformed_note.note).to eq(expected_url.to_s)
    end

    context 'when object does not have reference' do
      it 'returns object unchanged' do
        issue.update!(description: 'foo')

        transformed_issue = subject.transform(context, issue)

        expect(transformed_issue.description).to eq('foo')
      end
    end

    context 'when there are not matched urls' do
      let(:url) { 'https://my.gitlab.com/another/project/path/-/issues/1' }

      shared_examples 'returns object unchanged' do
        it 'returns object unchanged' do
          issue.update!(description: url)

          transformed_issue = subject.transform(context, issue)

          expect(transformed_issue.description).to eq(url)
        end
      end

      include_examples 'returns object unchanged'

      context 'when url path does not start with source full path' do
        let(:url) { 'https://my.gitlab.com/another/source/full/path/-/issues/1' }

        include_examples 'returns object unchanged'
      end

      context 'when host does not match and url path starts with source full path' do
        let(:url) { 'https://another.gitlab.com/source/full/path/-/issues/1' }

        include_examples 'returns object unchanged'
      end

      context 'when url does not match at all' do
        let(:url) { 'https://website.example/foo/bar' }

        include_examples 'returns object unchanged'
      end
    end
  end

  describe '#load' do
    it 'saves the object when object body changed' do
      transformed_issue = subject.transform(context, issue)
      transformed_note = subject.transform(context, issue_note)

      expect(transformed_issue).to receive(:save!)
      expect(transformed_note).to receive(:save!)

      subject.load(context, transformed_issue)
      subject.load(context, transformed_note)
    end

    context 'when object body is not changed' do
      it 'does not save the object' do
        expect(mr).not_to receive(:save!)
        expect(mr_note).not_to receive(:save!)
        expect(system_note).not_to receive(:save!)

        subject.load(context, mr)
        subject.load(context, mr_note)
        subject.load(context, system_note)
      end
    end
  end
end
