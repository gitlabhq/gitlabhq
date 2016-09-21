require 'spec_helper'

describe Gitlab::CrossReferenceExtractor, lib: true do
  context "as subtitute for mentionable commits" do
    # It's shared with the mentionable context should be other name
    subject { create(:project).commit }

    include_context 'mentionable context'

    describe '#references_by_object' do
      let(:author) { create(:user, email: subject.author_email) }
      let(:backref_text) { "commit #{subject.id}" }
      let(:set_mentionable_text) do
        ->(txt) { allow(subject).to receive(:safe_message).and_return(txt) }
      end

      # Include the subject in the repository stub.
      let(:extra_commits) { [subject] }

      let(:current_user) { author }

      it "extracts references from its reference property" do
        described_class.new(project, current_user).references_with_object([subject], :safe_message) do |object, refs|
          # De-duplicate and omit itself
          expect(object).to eq(subject)
          expect(refs.size).to eq(6)
          expect(refs).to include(mentioned_issue)
          expect(refs).to include(mentioned_mr)
          expect(refs).to include(mentioned_commit)
          expect(refs).to include(ext_issue)
          expect(refs).to include(ext_mr)
          expect(refs).to include(ext_commit)
        end
      end

      it "uses object author to redact references" do
        unknown_author = create(:user)

        expect(subject).to receive(:author).and_return(unknown_author).at_least(:once)

        described_class.new(project, current_user).references_with_object([subject], :safe_message) do |object, refs|
          expect(object).to eq(subject)
          expect(refs.size).to eq(5)
          expect(refs).not_to include(mentioned_issue)
          expect(refs).to include(mentioned_mr)
          expect(refs).to include(mentioned_commit)
          expect(refs).to include(ext_issue)
          expect(refs).to include(ext_mr)
          expect(refs).to include(ext_commit)
        end
      end
    end
  end
end
