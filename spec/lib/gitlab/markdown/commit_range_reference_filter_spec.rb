require 'spec_helper'

module Gitlab::Markdown
  describe CommitRangeReferenceFilter do
    include FilterSpecHelper

    let(:project) { create(:project) }
    let(:commit1) { project.commit }
    let(:commit2) { project.commit("HEAD~2") }

    let(:range)  { CommitRange.new("#{commit1.id}...#{commit2.id}") }
    let(:range2) { CommitRange.new("#{commit1.id}..#{commit2.id}") }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Commit Range #{range.to_reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      let(:reference)  { range.to_reference }
      let(:reference2) { range2.to_reference }

      it 'links to a valid two-dot reference' do
        doc = filter("See #{reference2}")

        expect(doc.css('a').first.attr('href')).
          to eq urls.namespace_project_compare_url(project.namespace, project, range2.to_param)
      end

      it 'links to a valid three-dot reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).
          to eq urls.namespace_project_compare_url(project.namespace, project, range.to_param)
      end

      it 'links to a valid short ID' do
        reference = "#{commit1.short_id}...#{commit2.id}"
        reference2 = "#{commit1.id}...#{commit2.short_id}"

        exp = commit1.short_id + '...' + commit2.short_id

        expect(filter("See #{reference}").css('a').first.text).to eq exp
        expect(filter("See #{reference2}").css('a').first.text).to eq exp
      end

      it 'links with adjacent text' do
        doc = filter("See (#{reference}.)")

        exp = Regexp.escape(range.to_s)
        expect(doc.to_html).to match(/\(<a.+>#{exp}<\/a>\.\)/)
      end

      it 'ignores invalid commit IDs' do
        exp = act = "See #{commit1.id.reverse}...#{commit2.id}"

        expect(project).to receive(:valid_repo?).and_return(true)
        expect(project.repository).to receive(:commit).with(commit1.id.reverse)
        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('title')).to eq range.reference_title
      end

      it 'includes default classes' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit_range'
      end

      it 'includes a data-project-id attribute' do
        doc = filter("See #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-project-id')
        expect(link.attr('data-project-id')).to eq project.id.to_s
      end

      it 'supports an :only_path option' do
        doc = filter("See #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_compare_url(project.namespace, project, from: commit1.id, to: commit2.id, only_path: true)
      end

      it 'adds to the results hash' do
        result = pipeline_result("See #{reference}")
        expect(result[:references][:commit_range]).not_to be_empty
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:project, namespace: namespace) }
      let(:reference) { range.to_reference(project) }

      before do
        range.project = project2
      end

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_compare_url(project2.namespace, project2, range.to_param)
        end

        it 'links with adjacent text' do
          doc = filter("Fixed (#{reference}.)")

          exp = Regexp.escape("#{project2.to_reference}@#{range.to_s}")
          expect(doc.to_html).to match(/\(<a.+>#{exp}<\/a>\.\)/)
        end

        it 'ignores invalid commit IDs on the referenced project' do
          exp = act = "Fixed #{project2.to_reference}@#{commit1.id.reverse}...#{commit2.id}"
          expect(filter(act).to_html).to eq exp

          exp = act = "Fixed #{project2.to_reference}@#{commit1.id}...#{commit2.id.reverse}"
          expect(filter(act).to_html).to eq exp
        end

        it 'adds to the results hash' do
          result = pipeline_result("See #{reference}")
          expect(result[:references][:commit_range]).not_to be_empty
        end
      end

      context 'when user cannot access reference' do
        before { disallow_cross_reference! }

        it 'ignores valid references' do
          exp = act = "See #{reference}"

          expect(filter(act).to_html).to eq exp
        end
      end
    end
  end
end
