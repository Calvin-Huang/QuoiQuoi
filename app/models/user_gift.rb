class UserGift < ApplicationRecord
  enum payment_method: {
      remittance: 0,
      paypal: 1,
      cvs_family: 2,
      cvs_ibon: 3,
      webatm: 4,
      atm: 5,
      alipay: 6,
      credit_card: 7,
      event: 8,
  }

  belongs_to :user
  belongs_to :gift
  belongs_to :order
  belongs_to :registration
  belongs_to :locale

  has_one :payment
  has_many :user_gift_serials, dependent: :destroy

  belongs_to :used_user, class_name: 'User', foreign_key: 'used_user_id'

  has_one :user_gift_payment, dependent: :destroy

  def paid?
    self.payment
  end

  # Force input value convert to integer
  def payment_method=(value)
    write_attribute(:payment_method, (value.is_a?(Integer))? value : value.to_i)
  end

  def has_expire_time?
    (self.remittance? || self.cvs_family? || self.cvs_ibon? || self.atm?) &&
        (!self.user_gift_payment.expire_time.nil?)
  end

  def empty_expire_time?
    (self.remittance? || self.cvs_family? || self.cvs_ibon? || self.atm?) &&
        (self.user_gift_payment.expire_time.nil?)
  end
end