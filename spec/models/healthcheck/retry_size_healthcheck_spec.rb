RSpec.describe Healthcheck::RetrySizeHealthcheck do
  before { allow(subject).to receive(:retry_size).and_return(size) }

  context "when there aren't many retries" do
    let(:size) { 2 }
    specify { expect(subject.status).to eq(:ok) }
  end

  context "when the warning threshold is reached" do
    let(:size) { 40005 }
    specify { expect(subject.status).to eq(:warning) }
  end

  context "when the critical threshold is reached" do
    let(:size) { 50010 }
    specify { expect(subject.status).to eq(:critical) }
  end

  describe "#details" do
    let(:size) { 3 }

    it "returns the number of retries" do
      expect(subject.details).to eq(retry_size: 3)
    end
  end
end
