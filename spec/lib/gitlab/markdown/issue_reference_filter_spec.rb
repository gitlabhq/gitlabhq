require 'spec_helper'

module Gitlab::Markdown
  describe IssueReferenceFilter do
    include ReferenceFilterSpecHelper

    def helper
      IssuesHelper
    end

    let(:project) { create(:empty_project) }
    let(:issue)   { create(:issue, project: project) }

    it 'requires project context' do
      expect { described_class.call('Issue #123', {}) }.
        to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Issue ##{issue.iid}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      let(:reference) { "##{issue.iid}" }

      it 'ignores valid references when using non-default tracker' do
        expect(project).to receive(:get_issue).with(issue.iid).and_return(nil)

        exp = act = "Issue ##{issue.iid}"
        expect(filter(act).to_html).to eq exp
      end

      it 'links to a valid reference' do
        doc = filter("Fixed #{reference}")

        expect(doc.css('a').first.attr('href')).
          to eq helper.url_for_issue(issue.iid, project)
      end

      it 'links with adjacent text' do
        doc = filter("Fixed (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
      end

      it 'ignores invalid issue IDs' do
        exp = act = "Fixed ##{issue.iid + 1}"

        expect(project).to receive(:get_issue).with(issue.iid + 1).and_return(nil)
        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("Issue #{reference}")
        expect(doc.css('a').first.attr('title')).to eq "Issue: #{issue.title}"
      end

      it 'escapes the title attribute' do
        issue.update_attribute(:title, %{"></a>whatever<a title="})

        doc = filter("Issue #{reference}")
        expect(doc.text).to eq "Issue #{reference}"
      end

      it 'includes default classes' do
        doc = filter("Issue #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-issue'
      end

      it 'includes an optional custom class' do
        doc = filter("Issue #{reference}", reference_class: 'custom')
        expect(doc.css('a').first.attr('class')).to include 'custom'
      end

      it 'supports an :only_path context' do
        doc = filter("Issue #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq helper.url_for_issue(issue.iid, project, only_path: true)
      end

      it 'adds to the results hash' do
        result = pipeline_result("Fixed #{reference}")
        expect(result[:references][:issue]).to eq [issue]
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:empty_project, namespace: namespace) }
      let(:issue)     { create(:issue, project: project2) }
      let(:reference) { "#{project2.path_with_namespace}##{issue.iid}" }

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'ignores valid references when cross-reference project uses external tracker' do
          expect_any_instance_of(Project).to receive(:get_issue).
            with(issue.iid).and_return(nil)

          exp = act = "Issue ##{issue.iid}"
          expect(filter(act).to_html).to eq exp
        end

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq helper.url_for_issue(issue.iid, project2)
        end

        it 'links with adjacent text' do
          doc = filter("Fixed (#{reference}.)")
          expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
        end

        it 'ignores invalid issue IDs on the referenced project' do
          exp = act = "Fixed #{project2.path_with_namespace}##{issue.iid + 1}"

          expect(filter(act).to_html).to eq exp
        end

        it 'adds to the results hash' do
          result = pipeline_result("Fixed #{reference}")
          expect(result[:references][:issue]).to eq [issue]
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
