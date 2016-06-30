require 'spec_helper'

describe PathLock, models: true do
  let!(:path_lock) { create(:path_lock, path: 'app/models') }
  let(:project) { path_lock.project }

  context 'Relations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
  end

  context 'Validations' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_uniqueness_of(:path).scoped_to(:project_id) }

    describe '#path_unique_validation' do
      it "is not valid because of upstream lock" do
        path_lock = build :path_lock, path: 'app/models/user.rb', project: project
        expect(path_lock.valid?).to be_falsey
        expect(path_lock.errors[:path].first).to match("upstream lock")
      end

      it "is not valid because of downstream lock" do
        path_lock = build :path_lock, path: 'app', project: project
        expect(path_lock.valid?).to be_falsey
        expect(path_lock.errors[:path].first).to match("downstream lock")
      end
    end
  end

  describe 'downstream?' do
    it "returns true" do
      expect(path_lock.downstream?("app")).to be_truthy
    end

    it "returns false" do
      expect(path_lock.downstream?("app/models")).to be_falsey
    end

    it "returns false" do
      expect(path_lock.downstream?("app/models/user.rb")).to be_falsey
    end
  end

  describe 'upstream?' do
    it "returns true" do
      expect(path_lock.upstream?("app/models/user.rb")).to be_truthy
    end

    it "returns false" do
      expect(path_lock.upstream?("app/models")).to be_falsey
    end

    it "returns false" do
      expect(path_lock.upstream?("app")).to be_falsey
    end
  end

  describe 'exact?' do
    it "returns true" do
      expect(path_lock.exact?("app/models")).to be_truthy
    end

    it "returns false" do
      expect(path_lock.exact?("app")).to be_falsey
    end
  end
end
