require 'spec_helper'

module Gitlab::Markdown
  describe MergeRequestReferenceFilter do
    include FilterSpecHelper

    let(:project) { create(:project) }
    let(:merge)   { create(:merge_request, source_project: project) }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Merge #{merge.to_reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      let(:reference) { merge.to_reference }

      it 'links to a valid reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq urls.
          namespace_project_merge_request_url(project.namespace, project, merge)
      end

      it 'links with adjacent text' do
        doc = filter("Merge (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
      end

      it 'ignores invalid merge IDs' do
        exp = act = "Merge #{invalidate_reference(reference)}"

        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("Merge #{reference}")
        expect(doc.css('a').first.attr('title')).to eq "Merge Request: #{merge.title}"
      end

      it 'escapes the title attribute' do
        merge.update_attribute(:title, %{"></a>whatever<a title="})

        doc = filter("Merge #{reference}")
        expect(doc.text).to eq "Merge #{reference}"
      end

      it 'includes default classes' do
        doc = filter("Merge #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-merge_request'
      end

      it 'includes a data-project-id attribute' do
        doc = filter("Merge #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-project-id')
        expect(link.attr('data-project-id')).to eq project.id.to_s
      end

      it 'supports an :only_path context' do
        doc = filter("Merge #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_merge_request_url(project.namespace, project, merge, only_path: true)
      end

      it 'adds to the results hash' do
        result = pipeline_result("Merge #{reference}")
        expect(result[:references][:merge_request]).to eq [merge]
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:project, namespace: namespace) }
      let(:merge)     { create(:merge_request, source_project: project2) }
      let(:reference) { merge.to_reference(project) }

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_merge_request_url(project2.namespace,
                                                          project, merge)
        end

        it 'links with adjacent text' do
          doc = filter("Merge (#{reference}.)")
          expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
        end

        it 'ignores invalid merge IDs on the referenced project' do
          exp = act = "Merge #{invalidate_reference(reference)}"

          expect(filter(act).to_html).to eq exp
        end

        it 'adds to the results hash' do
          result = pipeline_result("Merge #{reference}")
          expect(result[:references][:merge_request]).to eq [merge]
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
