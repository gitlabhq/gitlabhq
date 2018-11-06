require "spec_helper"

shared_examples_for "Interacts with external service" do |service_name, content_key:|
  it "calls #{service_name} Webhooks API" do
    subject.execute(sample_data)

    expect(WebMock).to have_requested(:post, webhook_url).with { |req| req.body =~ /\A{"#{content_key}":.+}\Z/ }.once
  end
end
