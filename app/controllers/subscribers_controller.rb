class SubscribersController < ApplicationController
  def subscriptions
    subscriber = find_subscriber(subscriber_params.require(:address))
    subscriptions = Subscription.active.
      includes(:subscriber_list).
      where(subscriber: subscriber).
      order('subscriber_lists.title').
      as_json(include: :subscriber_list)

    render json: { subscriber: subscriber.as_json, subscriptions: subscriptions }
  end

  def change_address
    subscriber = find_subscriber(subscriber_params.require(:address))
    subscriber.update!(address: subscriber_params.require(:new_address))
    render json: { subscriber: subscriber }
  end

  def auth_token
    subscriber = find_or_create_subscriber(auth_token_params.require(:address))
    token = AuthTokenGeneratorService.call(subscriber)
    # Send email with token
    render json: { subscriber: subscriber, token: token }, status: :created
  end

private

  def find_subscriber(address)
    Subscriber
      .find_by!("LOWER(address) = ?", address.downcase)
      .tap do |subscriber|
        subscriber.activate! if subscriber.deactivated?
      end
  end

  def find_or_create_subscriber(address)
    found = Subscriber.find_by("LOWER(address) = ?", address.downcase)
    found.activate! if found&.deactivated?
    found || Subscriber.create!(
      address: address,
      signon_user_uid: current_user.uid,
    )
  end

  def subscriber_params
    params.permit(:address, :new_address)
  end

  def auth_token_params
    params.permit(:address)
  end
end
