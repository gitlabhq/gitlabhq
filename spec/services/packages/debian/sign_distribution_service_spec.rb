# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Debian::SignDistributionService, feature_category: :package_registry do
  let_it_be(:group) { create(:group, :public) }

  let(:content) { FFaker::Lorem.paragraph }
  let(:service) { described_class.new(distribution, content, detach: detach) }

  shared_examples 'Sign Distribution' do |container_type, detach: false|
    context "for #{container_type} detach=#{detach}" do
      let(:detach) { detach }

      if container_type == :group
        let_it_be(:distribution) { create('debian_group_distribution', container: group) }
      else
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:distribution) { create('debian_project_distribution', container: project) }
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
              expect(subject).to start_with("-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\n#{content}\n-----BEGIN PGP SIGNATURE-----\n")
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
