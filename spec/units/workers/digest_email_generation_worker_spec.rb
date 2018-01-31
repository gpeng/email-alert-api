require 'rails_helper'

RSpec.describe DigestEmailGenerationWorker do
  let(:subscriber) { create(:subscriber, id: 1) }
  let!(:subscription_one) {
    create(:subscription, id: 1, subscriber_id: subscriber.id)
  }
  let!(:subscription_two) {
    create(:subscription, id: 2, subscriber_id: subscriber.id)
  }
  let!(:digest_run) { create(:digest_run, id: 10) }

  let(:subscription_content_change_query_results) {
    [
      double(
        subscription_id: 1,
        subscription_uuid: "ABC1",
        subscriber_list_title: "Test title 1",
        content_changes: [
          create(:content_change, public_updated_at: "1/1/2016 10:00"),
        ],
      ),
      double(
        subscription_id: 2,
        subscription_uuid: "ABC2",
        subscriber_list_title: "Test title 2",
        content_changes: [
          create(:content_change, public_updated_at: "4/1/2016 10:00"),
        ],
      ),
    ]
  }

  before do
    allow(SubscriptionContentChangeQuery).to receive(:call).and_return(
      subscription_content_change_query_results
    )
  end

  it "accepts digest_run_subscriber_id" do
    create(:digest_run_subscriber, id: 1)

    expect {
      subject.perform(1)
    }.not_to raise_error
  end

  it "creates an email" do
    create(:digest_run_subscriber, id: 1)

    expect { subject.perform(1) }
      .to change { Email.count }.by(1)
  end

  it "enqueues delivery" do
    expect(DeliveryRequestWorker).to receive(:perform_async_in_queue)
      .with(instance_of(Integer), queue: :delivery_digest)

    create(:digest_run_subscriber, id: 1)

    subject.perform(1)
  end

  it "records a metric for the delivery attempt" do
    expect(MetricsService).to receive(:digest_email_generation)
      .with("daily")

    create(:digest_run_subscriber, id: 1)

    subject.perform(1)
  end

  it "marks the DigestRunSubscriber completed" do
    digest_run_subscriber = create(
      :digest_run_subscriber,
      id: 1,
      subscriber_id: subscriber.id
    )

    allow(DigestRunSubscriber).to receive(:find)
      .with(1)
      .and_return(digest_run_subscriber)

    expect(digest_run_subscriber).to receive(:mark_complete!)

    subject.perform(1)
  end

  it "creates a SubscriptionContent" do
    create(
      :digest_run_subscriber,
      id: 1,
      subscriber_id: subscriber.id
    )

    subject.perform(1)

    subscription_content = SubscriptionContent.last
    expect(subscription_content.digest_run_subscriber_id).to eq(1)
  end

  it "marks the digest run complete" do
    create(:digest_run_subscriber, id: 1)
    expect_any_instance_of(DigestRun).to receive(:mark_complete!)
    subject.perform(1)
  end

  context "when there are incomplete DigestRunSubscribers left" do
    it "doesn't mark the digest run complete" do
      create(:digest_run_subscriber, id: 1, digest_run_id: digest_run.id)
      create(:digest_run_subscriber, digest_run_id: digest_run.id)
      expect_any_instance_of(DigestRun).not_to receive(:mark_complete!)
      subject.perform(1)
    end
  end
end