RSpec.describe "Creating a subscriber list", type: :request do
  let(:base_url) do
    config = EmailAlertAPI.config.gov_delivery
    "http://#{config.fetch(:hostname)}/api/account/#{config.fetch(:account_code)}"
  end

  let(:http_auth) do
    config = EmailAlertAPI.config.gov_delivery
    Base64.strict_encode64("#{config.fetch(:username)}:#{config.fetch(:password)}")
  end

  before do
    stub_request(:post, base_url + "/topics.xml")
      .with(headers: { "Authorization" => "Basic #{http_auth}" })
      .with(body: /This is a sample title/)
      .to_return(body: %{
        <?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <to-param>UKGOVUK_1234</to-param>
          <topic-uri>/api/account/UKGOVUK/topics/UKGOVUK_1234.xml</topic-uri>
          <link rel="self" href="/api/account/UKGOVUK/topics/UKGOVUK_1234"/>
        </topic>
      })
  end

  it "creates the topic on gov delivery" do
    create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

    body = <<-XML.strip_heredoc
      <?xml version="1.0"?>
      <topic>
        <name>This is a sample title</name>
        <short-name>This is a sample title</short-name>
        <visibility>Unlisted</visibility>
        <pagewatch-enabled type="boolean">false</pagewatch-enabled>
        <rss-feed-url nil="true"/>
        <rss-feed-title nil="true"/>
        <rss-feed-description nil="true"/>
      </topic>
    XML

    assert_requested(
      :post,
      base_url + "/topics.xml",
      headers: { 'Content-Type' => 'application/xml' },
      body: body,
      times: 1
    )
  end

  it "creates a subscriber_list" do
    create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

    subscriber_list = SubscriberList.last
    expect(subscriber_list).to have_attributes(gov_delivery_id: 'UKGOVUK_1234')
  end

  it "returns a 201" do
    create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

    expect(response.status).to eq(201)
  end

  it "returns the created subscriber list" do
    create_subscriber_list(
      tags: { topics: ["oil-and-gas/licensing"] },
      links: { topics: ["uuid-888"] }
    )
    response_hash = JSON.parse(response.body)
    subscriber_list = response_hash["subscriber_list"]

    expect(subscriber_list.keys.to_set).to eq(
      %w{
        id
        title
        document_type
        subscriber_count
        subscription_url
        gov_delivery_id
        created_at
        updated_at
        tags
        links
        email_document_supertype
        government_document_supertype
      }.to_set
    )
    expect(subscriber_list).to include(
      "tags" => {
        "topics" => ["oil-and-gas/licensing"]
      },
      "links" => {
        "topics" => ["uuid-888"]
      }
    )
  end

  it "returns an error if tag isn't an array" do
    create_subscriber_list(
      tags: { topics: "oil-and-gas/licensing" },
    )

    expect(response.status).to eq(422)
  end

  it "returns an error if creating the same topic" do
    stub_request(:post, base_url + "/topics.xml")
      .with(headers: { "Authorization" => "Basic #{http_auth}" })
      .with(body: /This is a sample title/)
      .to_return(body: %{
        <?xml version="1.0" encoding="UTF-8"?>
        <topic>
          <code>GD-14004</code>
          <error>conflict</error>
        </topic>
      })

    create_subscriber_list(tags: { topics: ["oil-and-gas/licensing"] })

    expect(response.status).to eq(409)
  end

  it "returns an error if link isn't an array" do
    create_subscriber_list(
      links: { topics: "uuid-888" },
    )

    expect(response.status).to eq(422)
  end

  describe "creating a subscriber list with a document_type" do
    it "returns a 201" do
      create_subscriber_list(document_type: "travel_advice")

      expect(response.status).to eq(201)
    end

    it "sets the document_type on the subscriber list" do
      create_subscriber_list(
        tags: { countries: ["andorra"] },
        document_type: "travel_advice"
      )

      subscriber_list = SubscriberList.last
      expect(subscriber_list.document_type).to eq("travel_advice")
    end
  end

  context "when creating a subscriber list with no tags or links" do
    context "and a document_type is provided" do
      it "returns a 201" do
        create_subscriber_list(document_type: "travel_advice")

        expect(response.status).to eq(201)
      end
    end
  end

  context "when creating a subscriber list with 'email' and 'government' document supertypes" do
    it "returns a 201" do
      create_subscriber_list(
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      )

      expect(response.status).to eq(201)

      expect(SubscriberList.last).to have_attributes(
        email_document_supertype: "publications",
        government_document_supertype: "news_stories",
      )
    end
  end

  def create_subscriber_list(payload = {})
    defaults = {
      title: "This is a sample title",
      tags: {},
      links: {},
    }

    request_body = JSON.dump(defaults.merge(payload))

    post "/subscriber-lists", params: request_body, headers: JSON_HEADERS
  end
end