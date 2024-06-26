# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::References::DesignReferenceFilter, feature_category: :design_management do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  let_it_be(:issue)         { create(:issue, iid: 10) }
  let_it_be(:issue_proj_2)  { create(:issue, iid: 20) }
  let_it_be(:issue_b)       { create(:issue, project: issue.project) }
  let_it_be(:developer)     { create(:user, developer_of: [issue.project, issue_proj_2.project]) }
  let_it_be(:design_a)      { create(:design, :with_versions, issue: issue) }
  let_it_be(:design_b)      { create(:design, :with_versions, issue: issue_b) }
  let_it_be(:design_proj_2) { create(:design, :with_versions, issue: issue_proj_2) }
  let_it_be(:project_with_no_lfs) { create(:project, :public, lfs_enabled: false) }

  let(:design)       { design_a }
  let(:project)      { issue.project }
  let(:project_2)    { issue_proj_2.project }
  let(:reference)    { design.to_reference }
  let(:design_url)   { url_for_design(design) }
  let(:input_text)   { "Added #{design_url}" }
  let(:doc)          { process_doc(input_text) }
  let(:current_user) { developer }

  before do
    enable_design_management
  end

  shared_examples 'a no-op filter' do
    it 'does nothing' do
      expect(process(input_text)).to eq(baseline(input_text).to_html)
    end
  end

  shared_examples 'a good link reference' do
    let(:link) { doc.css('a').first }
    let(:href) { url_for_design(design) }
    let(:title) { design.filename }

    it 'produces a good link', :aggregate_failures do
      expect(link.attr('href')).to eq(href)
      expect(link.attr('title')).to eq(title)
      expect(link.attr('class')).to eq('gfm gfm-design has-tooltip')
      expect(link.attr('data-project')).to eq(design.project.id.to_s)
      expect(link.attr('data-issue')).to eq(design.issue.id.to_s)
      expect(link.attr('data-original')).to eq(href)
      expect(link.attr('data-reference-type')).to eq('design')
      expect(link.text).to eq(design.to_reference(project))
    end
  end

  describe '.call' do
    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end
  end

  it 'does not error when we add redaction to the pipeline' do
    enable_design_management

    res = reference_pipeline(redact: true).to_document(input_text)

    expect(res.css('a').first).to be_present
  end

  describe '#call' do
    describe 'feature flags' do
      context 'design management is not enabled' do
        before do
          enable_design_management(false)
        end

        it_behaves_like 'a no-op filter'
      end
    end
  end

  %w[pre style].each do |elem|
    context "wrapped in a block <#{elem}/>" do
      let(:input_text) { "<#{elem}>Design #{url_for_design(design)}</#{elem}>" }

      it_behaves_like 'a no-op filter'
    end
  end

  it_behaves_like 'a no-op filter' do
    let(:input_text) { "`Design #{url_for_design(design)}`" }
  end

  describe '.identifier' do
    where(:filename) do
      [
        ['simple.png'],
        ['SIMPLE.PNG'],
        ['has-hyphen.jpg'],
        ['snake_case.svg']
      ]
    end

    with_them do
      let(:design) { build(:design, issue: issue, filename: filename) }
      let(:url) { url_for_design(design) }
      let(:pattern) { described_class.object_class.link_reference_pattern }
      let(:parsed) do
        m = pattern.match(url)
        described_class.new('', project: nil).identifier(m) if m
      end

      it 'can parse the reference' do
        expect(parsed).to have_attributes(
          filename: filename,
          issue_iid: issue.iid
        )
      end
    end
  end

  describe 'static properties' do
    specify do
      expect(described_class).to have_attributes(
        reference_type: :design,
        object_class: ::DesignManagement::Design
      )

      expect(described_class.new('', project: nil).object_sym).to eq :design
    end
  end

  describe '#data_attributes_for' do
    let(:subject) { filter_instance.data_attributes_for(input_text, project, design) }

    specify do
      is_expected.to include(
        issue: design.issue_id,
        original: input_text,
        project: project.id,
        design: design.id
      )
    end
  end

  context 'internal reference' do
    it_behaves_like 'a reference containing an element node'

    it_behaves_like 'a good link reference'

    context 'the filename contains invalid characters' do
      where(:filename) do
        [
          ['with some spaces.png'],
          ['with <script>console.log("pwded")<%2Fscript>.png'],
          ['foo"bar.png'],
          ['A "very" good file.png']
        ]
      end

      with_them do
        let(:design) { create(:design, :with_versions, filename: filename, issue: issue) }

        it_behaves_like 'a no-op filter'
      end
    end

    context 'the reference is to a non-existant design' do
      let(:design_url) { url_for_design(build(:design, issue: issue)) }

      it_behaves_like 'a no-op filter'
    end

    context 'design management is disabled for the referenced project' do
      let(:public_issue) { create(:issue, project: project_with_no_lfs) }
      let(:design) { create(:design, :with_versions, issue: public_issue) }

      it_behaves_like 'a no-op filter'
    end
  end

  describe 'link pattern' do
    let(:reference) { url_for_design(design) }

    it 'matches' do
      expect(reference).to match(DesignManagement::Design.link_reference_pattern)
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:design) { design_proj_2 }

    it_behaves_like 'a reference containing an element node'

    it_behaves_like 'a good link reference'

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href')).to eq(design_url)
    end

    context 'design management is disabled for that project' do
      let(:design) { create(:design, project: project_with_no_lfs) }

      it_behaves_like 'a no-op filter'
    end

    it 'link has valid text' do
      ref = "#{design.project.full_path}##{design.issue.iid}[#{design.filename}]"

      expect(doc.css('a').first.text).to eql(ref)
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-design has-tooltip'
    end

    context 'the reference is invalid' do
      let(:design_url) { url_for_design(design).gsub(/jpg/, 'gif') }

      it_behaves_like 'a no-op filter'
    end
  end

  describe 'performance' do
    it 'is linear in the number of projects with design management enabled each design refers to' do
      design_c = build(:design, :with_versions, issue: issue)
      design_d = build(:design, :with_versions, issue: issue_b)
      design_e = build(:design, :with_versions, issue: build_stubbed(:issue, project: project_2))

      one_ref_per_project = <<~MD
      Design #{url_for_design(design_a)}, #{url_for_design(design_proj_2)}
      MD

      multiple_references = <<~MD
      Designs that affect the count:
       * #{url_for_design(design_a)}
       * #{url_for_design(design_b)}
       * #{url_for_design(design_c)}
       * #{url_for_design(design_d)}
       * #{url_for_design(design_proj_2)}
       * #{url_for_design(design_e)}

     Things that do not affect the count:
       * #{url_for_design(build_stubbed(:design, project: project_with_no_lfs))}
       * #{url_for_designs(issue)}
       * #1[not a valid reference.gif]
      MD

      control = ActiveRecord::QueryRecorder.new { process(one_ref_per_project) }

      # each project mentioned requires 2 queries:
      #
      #  * SELECT "issues".* FROM "issues" WHERE "issues"."project_id" = 1 AND ...
      #      :in `parent_records'*/
      #  * SELECT "_designs".* FROM "_designs"
      #      WHERE (issue_id = ? AND filename = ?) OR ...
      #      :in `parent_records'*/
      #
      # In addition there is a 1 query overhead for all the projects at the
      # start. Currently, the baseline for 2 projects is `2 * 2 + 1 = 5` queries
      #
      expect { process(multiple_references) }.not_to exceed_query_limit(control)
    end
  end

  private

  def process_doc(text)
    reference_filter(text, project: project)
  end

  def baseline(text)
    null_filter(text, project: project)
  end

  def process(text)
    process_doc(text).to_html
  end
end
