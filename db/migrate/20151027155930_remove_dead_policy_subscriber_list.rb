class RemoveDeadPolicySubscriberList < ActiveRecord::Migration
  def up
    # This list doesn't match anything except similarly named placeholders in
    # the Content Store.
    target_list = SubscriberListQuery.new.find_exact_match_with(
      { policy: ["inspections-of-schools-colleges-and-children-s-services"] }
    ).first

    if target_list.present?
      target_list.destroy!
    end
  end

  def down
    # noop
  end
end