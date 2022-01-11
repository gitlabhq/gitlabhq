# frozen_string_literal: true

RSpec.shared_examples Integrations::ChatMessage do
  context 'when input contains link markup' do
    let(:evil_input) { '[Markdown](http://evil.com) <a href="http://evil.com">HTML</a> <http://evil.com|Slack>' }

    # Attributes returned from #activity and #attributes which should be sanitized.
    let(:sanitized_attributes) do
      %i[title subtitle text fallback author_name]
    end

    # Attributes passed to #initialize which can contain user input.
    before do
      args.deep_merge!(
        project_name: evil_input,
        user_name: evil_input,
        user_full_name: evil_input,
        commit_title: evil_input,
        environment: evil_input,
        project: {
          name: evil_input
        },
        user: {
          name: evil_input,
          username: evil_input
        },
        object_attributes: {
          title: evil_input
        }
      )
    end

    # NOTE: The `include` matcher is used here so the RSpec error messages will tell us
    # which method or attribute is failing, even though it makes the spec a bit less readable.
    it 'strips all link markup characters', :aggregate_failures do
      expect(subject).not_to have_attributes(
        pretext: include(evil_input),
        summary: include(evil_input)
      )

      begin
        sanitized_attributes.each do |attribute|
          expect(subject.activity).not_to include(attribute => include(evil_input))
        end
      rescue NotImplementedError
      end

      begin
        sanitized_attributes.each do |attribute|
          expect(subject.attachments).not_to include(include(attribute => include(evil_input)))
        end
      rescue NotImplementedError
      end
    end
  end
end
