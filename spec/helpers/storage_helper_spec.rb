# frozen_string_literal: true

require "spec_helper"

RSpec.describe StorageHelper do
  describe "#storage_counter" do
    it "formats bytes to one decimal place" do
      expect(helper.storage_counter(1.23.megabytes)).to eq("1.2 MB")
    end

    it "does not add decimals for sizes < 1 MB" do
      expect(helper.storage_counter(23.5.kilobytes)).to eq("24 KB")
    end

    it "does not add decimals for zeroes" do
      expect(helper.storage_counter(2.megabytes)).to eq("2 MB")
    end

    it "uses commas as thousands separator" do
      expect(helper.storage_counter(100_000_000_000_000_000_000_000)).to eq("86,736.2 EB")
    end
  end

  describe "#storage_counters_details" do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) do
      create(:project,
             namespace: namespace,
             statistics: build(:project_statistics,
                               namespace:               namespace,
                               repository_size:         10.kilobytes,
                               wiki_size:               10.bytes,
                               lfs_objects_size:        20.gigabytes,
                               build_artifacts_size:    30.megabytes,
                               pipeline_artifacts_size: 11.megabytes,
                               snippets_size:           40.megabytes,
                               packages_size:           12.megabytes,
                               uploads_size:            15.megabytes))
    end

    let(:message) { 'Repository: 10 KB / Wikis: 10 Bytes / Build Artifacts: 30 MB / Pipeline Artifacts: 11 MB / LFS: 20 GB / Snippets: 40 MB / Packages: 12 MB / Uploads: 15 MB' }

    it 'works on ProjectStatistics' do
      expect(helper.storage_counters_details(project.statistics)).to eq(message)
    end

    it 'works on Namespace.with_statistics' do
      namespace_stats = Namespace.with_statistics.find(project.namespace.id)

      expect(helper.storage_counters_details(namespace_stats)).to eq(message)
    end
  end

  describe "storage_enforcement_banner", :saas do
    let_it_be_with_refind(:current_user) { create(:user) }
    let_it_be(:free_group) { create(:group) }
    let_it_be(:paid_group) { create(:group) }

    before do
      allow(helper).to receive(:can?).with(current_user, :maintain_namespace, free_group).and_return(true)
      allow(helper).to receive(:can?).with(current_user, :maintain_namespace, paid_group).and_return(true)
      allow(helper).to receive(:current_user) { current_user }
      allow(paid_group).to receive(:paid?).and_return(true)

      stub_feature_flags(namespace_storage_limit_bypass_date_check: false)
    end

    describe "#storage_enforcement_banner_info" do
      it 'returns nil when namespace is not free' do
        expect(helper.storage_enforcement_banner_info(paid_group)).to be(nil)
      end

      it 'returns nil when storage_enforcement_date is not set' do
        allow(free_group).to receive(:storage_enforcement_date).and_return(nil)

        expect(helper.storage_enforcement_banner_info(free_group)).to be(nil)
      end

      describe 'when storage_enforcement_date is set' do
        let_it_be(:storage_enforcement_date) { Date.today + 30 }

        before do
          allow(free_group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end

        it 'returns nil when current_user do not have access usage quotas page' do
          allow(helper).to receive(:can?).with(current_user, :maintain_namespace, free_group).and_return(false)

          expect(helper.storage_enforcement_banner_info(free_group)).to be(nil)
        end

        it 'returns nil when namespace_storage_limit_show_preenforcement_banner FF is disabled' do
          stub_feature_flags(namespace_storage_limit_show_preenforcement_banner: false)

          expect(helper.storage_enforcement_banner_info(free_group)).to be(nil)
        end

        context 'when current_user can access the usage quotas page' do
          it 'returns a hash' do
            expect(helper.storage_enforcement_banner_info(free_group)).to eql({
              text: "From #{storage_enforcement_date} storage limits will apply to this namespace. You are currently using 0 Bytes of namespace storage. View and manage your usage from <strong>Group settings &gt; Usage quotas</strong>.",
              variant: 'warning',
              callouts_feature_name: 'storage_enforcement_banner_second_enforcement_threshold',
              callouts_path: '/-/users/group_callouts',
              learn_more_link: '<a rel="noopener noreferrer" target="_blank" href="/help//">Learn more.</a>'
            })
          end

          context 'when namespace has used storage' do
            before do
              create(:namespace_root_storage_statistics, namespace: free_group, storage_size: 102400)
            end

            it 'returns a hash with the correct storage size text' do
              expect(helper.storage_enforcement_banner_info(free_group)[:text]).to eql("From #{storage_enforcement_date} storage limits will apply to this namespace. You are currently using 100 KB of namespace storage. View and manage your usage from <strong>Group settings &gt; Usage quotas</strong>.")
            end
          end

          context 'when the given group is a sub-group' do
            let_it_be(:sub_group) { build(:group) }

            before do
              allow(sub_group).to receive(:root_ancestor).and_return(free_group)
            end

            it 'returns the banner hash' do
              expect(helper.storage_enforcement_banner_info(sub_group).keys).to match_array(%i(text variant callouts_feature_name callouts_path learn_more_link))
            end
          end
        end
      end

      context 'when the :storage_banner_bypass_date_check is enabled', :freeze_time do
        before do
          stub_feature_flags(namespace_storage_limit_bypass_date_check: true)
        end

        it 'returns the enforcement info' do
          expect(helper.storage_enforcement_banner_info(free_group)[:text]).to include("From #{Date.current} storage limits will apply to this namespace.")
        end
      end

      context 'when storage_enforcement_date is set and dismissed callout exists' do
        before do
          create(:group_callout,
                 user: current_user,
                 group_id: free_group.id,
                 feature_name: 'storage_enforcement_banner_second_enforcement_threshold')
          storage_enforcement_date = Date.today + 30
          allow(free_group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)
        end

        it { expect(helper.storage_enforcement_banner_info(free_group)).to be(nil) }
      end

      context 'callouts_feature_name' do
        let(:days_from_now) { 45 }

        subject do
          storage_enforcement_date = Date.today + days_from_now
          allow(free_group).to receive(:storage_enforcement_date).and_return(storage_enforcement_date)

          helper.storage_enforcement_banner_info(free_group)[:callouts_feature_name]
        end

        it 'returns first callouts_feature_name' do
          is_expected.to eq('storage_enforcement_banner_first_enforcement_threshold')
        end

        context 'returns second callouts_feature_name' do
          let(:days_from_now) { 20 }

          it { is_expected.to eq('storage_enforcement_banner_second_enforcement_threshold') }
        end

        context 'returns third callouts_feature_name' do
          let(:days_from_now) { 13 }

          it { is_expected.to eq('storage_enforcement_banner_third_enforcement_threshold') }
        end

        context 'returns fourth callouts_feature_name' do
          let(:days_from_now) { 3 }

          it { is_expected.to eq('storage_enforcement_banner_fourth_enforcement_threshold') }
        end
      end
    end
  end
end
