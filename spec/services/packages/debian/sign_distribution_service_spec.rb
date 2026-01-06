# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::SignDistributionService, feature_category: :package_registry do
  let_it_be(:group) { create(:group, :public) }

  let(:content) { FFaker::Lorem.paragraph }
  let(:service) { described_class.new(distribution, content, detach: detach) }

  shared_examples 'Sign Distribution' do |container_type, detach: false|
    context "for #{container_type} detach=#{detach}" do
      let(:detach) { detach }

      # Use `let` instead of `let_it_be` for distributions to avoid test pollution.
      # The key created in 'with an existing key' context would persist across
      # examples when using `let_it_be`, causing 'without an existing key' tests
      # to fail when they run after 'with an existing key' tests.
      if container_type == :group
        let(:distribution) { create('debian_group_distribution', container: group) }
      else
        let(:project) { create(:project, group: group) }
        let(:distribution) { create('debian_project_distribution', container: project) }
      end

      describe '#execute' do
        subject { service.execute }

        context 'without an existing key' do
          it 'raises ArgumentError', :aggregate_failures do
            expect { subject }
              .to raise_error(ArgumentError, 'distribution key is missing')
          end
        end

        context 'with an existing key' do
          let!(:key) { create("debian_#{container_type}_distribution_key", distribution: distribution) }

          it 'returns the content signed', :aggregate_failures do
            expect(Packages::Debian::GenerateDistributionKeyService).not_to receive(:new)

            key_class = "Packages::Debian::#{container_type.capitalize}DistributionKey".constantize

            expect { subject }
              .to not_change { key_class.count }

            if detach
              expect(subject).to start_with("-----BEGIN PGP SIGNATURE-----\n")
            else
              # The hash algorithm depends on GPG version: 2.4.x uses SHA512, 2.2.x uses SHA256
              expect(subject).to match(/\A-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA(256|512)\n\n#{Regexp.escape(content)}\n-----BEGIN PGP SIGNATURE-----\n/)
            end

            expect(subject).to end_with("\n-----END PGP SIGNATURE-----\n")
          end
        end
      end
    end
  end

  it_behaves_like 'Sign Distribution', :project
  it_behaves_like 'Sign Distribution', :project, detach: true
  it_behaves_like 'Sign Distribution', :group
  it_behaves_like 'Sign Distribution', :group, detach: true
end
