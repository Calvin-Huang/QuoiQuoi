
class NotifierPreview < ActionMailer::Preview
  def registration_payment_remind
    RegistrationMailer.remind_to_pay(195, I18n.translate('mailer.subject.payment.remittance'))
  end

  def registration_payment_completed
    RegistrationMailer.completed_confirmation(195)
  end

  def registration_remittance_report
    RegistrationMailer.remind_remittance_report(14)
  end

  def registration_remittance_wrong
    RegistrationMailer.request_remit_payment_again(14)
  end

  def cancel_notification
    # CourseMailer.cancel_notification_individual('ts01364362@gmail.com', 185, '療癒系襪娃手作課：cat 兔you', 2, 'zh-TW', 'false')
    RegistrationMailer.cancel_notification(196)
  end

  def course_time_remind
    RegistrationMailer.remind_before_course_start(195)
  end

  def order_payment_remind
    OrderMailer.remind_to_pay(486, I18n.translate('mailer.subject.payment.remittance'))
  end

  # Send mail to manager for notification
  def order_remittance_report
    OrderMailer.remind_remittance_report(9)
  end

  # Send mail to manager for notification
  def order_remind_completed
    OrderMailer.remind_completed(516)
  end

  # Send mail to manager for notification
  def order_remind_deliver_problem
    OrderMailer.report_deliver_problem(525)
  end

  def order_remittance_wrong
    OrderMailer.request_remit_payment_again(9)
  end

  def order_payment_completed
    OrderMailer.completed_confirmation(516)
  end

  def order_delivered
    OrderMailer.deliver_notification(516)
  end

  def custom_dismiss
    CustomMailer.dismiss(7)
  end

  def custom_approve
    CustomMailer.approve(7)
  end

  def custom_remind
    CustomMailer.remind_new_order(7)
  end

  def remind_message_user
    MessageMailer.remind_to_user(33)
  end

  def remind_message_admin
    MessageMailer.remind_to_admin(35)
  end
end