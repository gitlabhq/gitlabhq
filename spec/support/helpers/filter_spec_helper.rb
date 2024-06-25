# frozen_string_literal: true

# Helper methods for Banzai filter specs
#
# Must be included into specs manually
module FilterSpecHelper
  extend ActiveSupport::Concern

  # Perform `call` on the described class
  #
  # Automatically passes the current `project` value, if defined, to the context
  # if none is provided.
  #
  # html     - HTML String to pass to the filter's `call` method.
  # context - Hash context for the filter. (default: {project: project})
  #
  # Returns a Nokogiri::XML::DocumentFragment
  def filter(html, context = {}, result = nil)
    if defined?(project)
      context.reverse_merge!(project: project)
    end

    render_context = Banzai::RenderContext
      .new(context[:project], context[:current_user])

    context = context.merge(render_context: render_context)

    described_class.call(html, context, result)
  end

  # Get an instance of the Filter class
  #
  # Use this for testing instance methods, but remember to test the result of
  # the full pipeline by calling #call using the other methods in this helper.
  def filter_instance
    context = { project: project, current_user: current_user, render_context: render_context }

    described_class.new(input_text, context)
  end

  def render_context
    Banzai::RenderContext.new(project, current_user)
  end

  # Run text through HTML::Pipeline with the current filter and return the
  # result Hash
  #
  # body     - String text to run through the pipeline
  # context - Hash context for the filter. (default: {project: project})
  #
  # Returns the Hash
  def pipeline_result(body, context = {})
    context.reverse_merge!(project: project) if defined?(project)

    pipeline = HTML::Pipeline.new([described_class], context)
    pipeline.call(body)
  end

  def reference_pipeline(filter: described_class, **context)
    context.reverse_merge!(project: project) if defined?(project)
    context.reverse_merge!(current_user: current_user) if defined?(current_user)

    filters = [Banzai::Filter::MarkdownFilter, filter].compact

    redact = context.delete(:redact)
    filters.push(Banzai::Filter::ReferenceRedactorFilter) if redact

    HTML::Pipeline.new(filters, context)
  end

  def reference_pipeline_result(body, context = {})
    reference_pipeline(context).call(body)
  end

  def reference_filter(text, context = {})
    reference_pipeline(**context).to_document(text)
  end

  # Use to test no-ops
  def null_filter(text, context = {})
    reference_pipeline(filter: nil, **context).to_document(text)
  end

  # Modify a String reference to make it invalid
  #
  # Commit SHAs get reversed, IDs get incremented by 1, all other Strings get
  # their word characters reversed.
  #
  # reference - String reference to modify
  #
  # Returns a String
  def invalidate_reference(reference)
    case reference
    when /\A(.+)?[^\d]\d+\z/
      # Integer-based reference with optional project prefix
      reference.gsub(/\d+\z/) { |i| i.to_i + 10_000 }
    when /\A(.+@)?(#{Gitlab::Git::Commit::RAW_SHA_PATTERN}\z)/o
      # SHA-based reference with optional prefix
      reference.gsub(/#{Gitlab::Git::Commit::RAW_SHA_PATTERN}\z/o) { |v| v.reverse }
    else
      reference.gsub(/\w+\z/) { |v| v.reverse }
    end
  end

  # Shortcut to Rails' auto-generated routes helpers, to avoid including the
  # module
  def urls
    Gitlab::Routing.url_helpers
  end
end
