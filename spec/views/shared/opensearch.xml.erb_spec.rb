require 'spec_helper'

describe 'shared/opensearch.xml.erb' do
  before do
    allow(view).to receive_messages(gitlab_host: 'mock-host.com',
                                    favicon_path: '/mock/favicon',
                                    search_url: '/mock/search',
                                    description: 'Search mock-host.com GitLab',
                                    long_name: 'mock-host.com GitLab search')

    render

    @rendered_xml = Nokogiri::XML(rendered)
  end

  it 'includes the short name' do
    expect(@rendered_xml.css('//ShortName').text).to have_content('GitLab search')
  end

  it 'includes the long name' do
    expect(@rendered_xml.css('//LongName').text).to have_content('mock-host.com GitLab search')
  end

  it 'includes the description' do
    expect(@rendered_xml.css('//Description').text).to have_content('Search mock-host.com GitLab')
  end

  it 'includes the gitlab favicon path in the image tag' do
    expect(@rendered_xml.css('//Image').text).to have_content('/mock/favicon')
  end

  it 'includes the gitlab search path in the url tag' do
    expect(@rendered_xml.css('//Url').first['template']).to have_content('/mock/search')
  end

  it 'should be a OpenSearchDescription document' do
    document = Nokogiri::XML::Schema(File.read(Rails.root.join('spec/fixtures/OpenSearchDescription.xsd')))
    errors = document.validate(@rendered_xml)
    aggregate_failures 'document validation' do
      errors.each { |error| expect(error).to be(nil) }
    end
  end
end
