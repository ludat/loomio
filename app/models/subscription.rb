class Subscription < ApplicationRecord
  include SubscriptionConcern if Object.const_defined?('SubscriptionConcern')

  PAYMENT_METHODS = ["chargify", "manual", "barter", "paypal"]

  has_many :groups
  belongs_to :owner, class_name: 'User'

  attr_accessor :chargify_product_id

  has_paper_trail

  def self.for(group)
    parent = group.parent_or_self
    parent.subscription || begin
      parent.subscription = Subscription.new
      parent.save
      parent.subscription
    end
  end

  def level
    SubscriptionService::PLANS[self.plan][:level]
  end

  def config
    SubscriptionService::PLANS[Subscription.last.plan.to_sym]
  end

  def is_active?
    # allow groups in dunning or on hold to continue using the app
    self.state == 'active' or self.state == 'past_due' or self.state == 'on_hold' or (self.state == 'trialing' && self.expires_at > Time.current)
  end

  def management_link
    (self.info || {})['chargify_management_link']
  end

  def self.ransackable_attributes(auth_object = nil)
    ["activated_at",
     "canceled_at",
     "chargify_subscription_id",
     "created_at",
     "expires_at",
     "id",
     "info",
     "max_members",
     "max_orgs",
     "max_threads",
     "members_count",
     "owner_id",
     "payment_method",
     "plan",
     "renewed_at",
     "renews_at",
     "state",
     "updated_at"]
  end
end
