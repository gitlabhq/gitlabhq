# frozen_string_literal: true

module DocUrlHelper
  def version
    "13.4.0-ee"
  end

  def doc_url(documentation_base_url)
    "#{documentation_base_url}/13.4/ee/#{path}.html"
  end

  def doc_url_without_version(documentation_base_url)
    "#{documentation_base_url}/ee/#{path}.html"
  end

  def stub_doc_file_read(content:, file_name: 'index.md')
    expect_file_read(File.join(Rails.root, 'doc', file_name), content: content)
  end
end

DocUrlHelper.prepend_mod
