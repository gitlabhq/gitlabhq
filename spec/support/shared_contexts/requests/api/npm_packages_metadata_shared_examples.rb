# frozen_string_literal: true

RSpec.shared_examples 'generates metadata response "on-the-fly"' do
  let(:metadata) do
    {
      'dist-tags' => {
        'latest' => package.version
      },
      'name' => package.name,
      'versions' => {
        package.version => {
          'dist' => {
            'shasum' => 'be93151dc23ac34a82752444556fe79b32c7a1ad',
            'tarball' => "http://localhost/api/v4/projects/#{project.id}/packages/npm/#{package.name}/-/foo-1.0.1.tgz"
          },
          'name' => package.name,
          'version' => package.version
        }
      }
    }
  end

  before do
    Grape::Endpoint.before_each do |endpoint|
      expect(endpoint).not_to receive(:present_carrierwave_file!) # rubocop:disable RSpec/ExpectInHook
    end
  end

  after do
    Grape::Endpoint.before_each nil
  end

  it 'generates metadata response "on-the-fly"', :aggregate_failures do
    expect(Packages::Npm::GenerateMetadataService).to receive(:new).and_call_original

    subject

    expect(json_response).to eq(metadata)
  end
end
