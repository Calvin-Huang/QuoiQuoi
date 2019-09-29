require 'csv'

class Admin::OrdersController < AdminController
  authorize_resource
  before_action :set_order, only: [:edit, :show, :update]
  before_action :set_shipping_fee, only: [:edit, :show]
  before_action :set_discount, only: [:edit, :show]
  add_breadcrumb '首頁', :admin_root_path

  # GET /admin/orders
  # GET /admin/orders.json
  def index
    conditions = {}

    unless search_filter_params.nil?
      @search_filter = search_filter_params
      conditions = search_filter_params

      unless conditions['order_payments']['completed'].nil?
        if conditions['order_payments']['completed'].include? 'false'
          conditions['order_payments']['completed'] << nil
        end

        conditions['order_payments']['completed'] = conditions['order_payments']['completed'].map do |completedCondition|
          case completedCondition
          when 'true'
            true
          when 'false'
            false
          end
        end
      end

      unless conditions['delivered'].nil?
        if conditions['delivered'].include? 'false'
          conditions['delivered'] << nil
        end
        conditions['delivered'] = conditions['delivered'].map do |deliveredCondition|
          case deliveredCondition
          when 'true'
            true
          when 'false'
            false
          end
        end
      end

      # Unless the completed_time is not nil, translate it to date range for rails.
      unless conditions['order_payments']['completed_time'].nil?
        dates = conditions['order_payments']['completed_time'].split(' - ')
        conditions['order_payments']['completed_time'] = dates[0]..dates[1]
      end

      # Unless the delivered_time is not nil, translate it to date range for rails.
      unless conditions['delivered_time'].nil?
        dates = conditions['delivered_time'].split(' - ')
        conditions['delivered_time'] = dates[0]..dates[1]
      end

      # Unless the closed_time is not nil, translate it to date range for rails.
      unless conditions['closed_time'].nil?
        dates = conditions['closed_time'].split(' - ')

        # Including not archived items.
        conditions['closed_time'] = [dates[0]..dates[1], nil]
      end
    end

    @orders = Order.includes(:order_payment).where(conditions).where.not(order_payments: {id: nil})
  end

  # GET /admin/orders/canceled
  def canceled
    @orders = Order.includes(:order_payment).where(order_payments: {cancel: true})

    unless cancel_search_filter_params.nil?
      @search_filter = cancel_search_filter_params
      conditions = cancel_search_filter_params

      unless conditions['cancel_time'].nil?
        dates = conditions['cancel_time'].split(' - ')
        conditions['cancel_time'] = dates[0]..dates[1]

        # Add search conditions to orders
        @orders = @orders.where(order_payments: conditions)
      end
    end
  end

  def closed
    @orders = Order.where(checkout: true, canceled: false, closed: true)
  end

  # GET /admin/orders/1
  # GET /admin/orders/1.json
  def show
    add_breadcrumb '訂單記錄', :admin_orders_path
    add_breadcrumb '訂單詳細內容'
  end

  def edit
    add_breadcrumb '待出貨訂單', :deliver_admin_orders_path
    add_breadcrumb '訂單詳細內容'
  end

  def deliver
    @search_filter = params[:search_filter] || %w[waiting delivered problem]
    @orders = Order.includes(:order_payment).where(order_payments: {completed: true}, closed: false)
    unless @search_filter.include?('waiting')
      @orders = @orders.where.not(delivered: false)
    end

    unless @search_filter.include?('delivered')
      @orders = @orders.where.not(delivered: true)
    end

    unless @search_filter.include?('problem')
      @orders = @orders.where.not(delivery_report: true)
    end
  end

  def archive
    @search_filter = archive_search_filter_params || Order.payment_methods.map{|payment_method| payment_method[1]}

    @orders = Order.includes(:order_payment).where(order_payments: {completed: true}, closed: true, payment_method: @search_filter)
  end

  # PATCH/PUT /admin/orders/1
  # PATCH/PUT /admin/orders/1.json
  def update
    if order_params[:closed]
      @order.closed = true
      @order.closed_time = Time.now
    elsif order_params[:delivery_report_handled]
      @order.delivery_report_handled = true
      @order.delivery_report_handled_time = Time.now
    elsif order_params[:delivered]
      @order.delivered = true
      @order.delivered_time = Time.now

      OrderMailer.deliver_notification(@order.id).deliver_later if @order.delivered?
    end

    @order.save!

    flash[:id] = @order.id
    flash[:closed] = order_params[:closed]
    flash[:delivery_report_handled] = order_params[:delivery_report_handled]
    flash[:delivered] = order_params[:delivered]

    redirect_to action: :deliver
  end

  # DELETE /admin/orders/1
  # DELETE /admin/orders/1.json
  def destroy
    if Order.find(params[:id]).destroy!
      redirect_to (params[:from_cancel] == 'true')? canceled_admin_orders_path : admin_orders_path
    end

    flash[:id] = params[:id]
  end

  def set_order
    @order = Order.find(params[:id])
  end

  def set_shipping_fee
    @shipping_fee = ShippingFeeTranslate.where(locale_id: @order.locale_id, shipping_fee_id: @order.shipping_fee_id).first
    if @shipping_fee.free_condition && @order.subtotal >= @shipping_fee.free_condition
      @shipping_fee.fee = 0
    end
  end

  def set_discount
    @discount = 0
    UserGiftSerial.where(order_id: @order.id).each do |user_gift_serial|
      @discount += user_gift_serial.user_gift.gift.gift_translates.where(locale_id: @order.locale_id).first.quota
    end
  end

  def order_params
    params.permit(:closed, :delivery_report_handled, :delivered)
  end

  def archive_search_filter_params
    (params[:search_filter].nil?)? params[:search_filter] : params[:search_filter].map{|value| value.to_i}
  end

  def cancel_search_filter_params
    unless params[:search_filter].nil?
      sanitize_params = params[:search_filter].permit(:cancel_time)
      sanitize_params.delete('cancel_time') if sanitize_params['cancel_time'].blank?
      sanitize_params
    end
  end

  def search_filter_params
    unless params[:search_filter].nil?
      sanitize_params = params[:search_filter].permit(:delivered_time, :closed, :closed_time,
                                                      order_payments: [{completed: []}, :completed_time],
                                                      payment_method: [],
                                                      delivered: [])
      sanitize_params['payment_method'] = sanitize_params['payment_method'].map{|value| value.to_i} unless sanitize_params['payment_method'].nil?
      sanitize_params['order_payments'].delete('completed_time') if sanitize_params['order_payments']['completed_time'].blank?
      sanitize_params.delete('delivered_time') if sanitize_params['delivered_time'].blank?

      if sanitize_params['closed'].nil?
        sanitize_params['closed'] = false
      else
        sanitize_params.delete('closed')
        sanitize_params.delete('closed_time') if sanitize_params['closed_time'].blank?
      end

      sanitize_params
    end
  end

  def download_csv
    conditions = {}

    unless search_filter_params.nil?
      @search_filter = search_filter_params
      conditions = search_filter_params

      unless conditions['order_payments']['completed'].nil?
        if conditions['order_payments']['completed'].include? 'false'
          conditions['order_payments']['completed'] << nil
        end

        conditions['order_payments']['completed'] = conditions['order_payments']['completed'].map do |completedCondition|
          case completedCondition
          when 'true'
            true
          when 'false'
            false
          end
        end
      end

      unless conditions['delivered'].nil?
        if conditions['delivered'].include? 'false'
          conditions['delivered'] << nil
        end
        conditions['delivered'] = conditions['delivered'].map do |deliveredCondition|
          case deliveredCondition
          when 'true'
            true
          when 'false'
            false
          end
        end
      end

      # Unless the completed_time is not nil, translate it to date range for rails.
      unless conditions['order_payments']['completed_time'].nil?
        dates = conditions['order_payments']['completed_time'].split(' - ')
        conditions['order_payments']['completed_time'] = dates[0]..dates[1]
      end

      # Unless the delivered_time is not nil, translate it to date range for rails.
      unless conditions['delivered_time'].nil?
        dates = conditions['delivered_time'].split(' - ')
        conditions['delivered_time'] = dates[0]..dates[1]
      end

      # Unless the closed_time is not nil, translate it to date range for rails.
      unless conditions['closed_time'].nil?
        dates = conditions['closed_time'].split(' - ')

        # Including not archived items.
        conditions['closed_time'] = [dates[0]..dates[1], nil]
      end
    end

    @orders = Order.includes(:order_payment).where(conditions).where.not(order_payments: {id: nil})

    csv_data = CSV.generate({}) do |csv|
      csv << [
        'id',
        '訂單已取消',
        '訂單金額',
        '會員資訊',
        '姓名',
        '電話',
        '區號',
        '地址',
        '付款金額',
        '付款完成時間',
        '訂單寄出時間',
        '訂單問題回報',
        '訂單關閉(已完成配送)'
      ]
      @orders.each do |order|
        order_payment = order.order_payment || OrderPayment.new
        csv << [
          order.id,
          order_payment.cancel? ? "#{order_payment.cancel_reason} (#{order_payment.cancel_time.strftime('%Y/%m/%d %H:%I:%S')})" : '',
          order.subtotal,
          "https://quoiquoi.tw/admin/users/#{order.user_id}",
          order.name,
          order.phone,
          order.zip_code,
          order.address,
          order_payment.completed? ? "#{order.currency} #{order_payment.amount} (#{order.payment_method})" : '',
          order_payment.completed? ? order_payment.completed_time.strftime('%Y/%m/%d %H:%I:%S') : '尚未完成付款',
          order.delivered? ? order.delivered_time.strftime('%Y/%m/%d %H:%I:%S') : '尚未寄出',
          order.delivery_report? ? "#{order.delivery_report_message} (#{delivery_report_time.strftime('%Y/%m/%d %H:%I:%S')})" : '',
          order.closed_time.nil? ? '' : '已完成'
        ]
      end
    end

    respond_to do |format|
      format.csv { send_data csv_data, filename: "#{Time.now.strftime('%Y/%m/%d_%H:%M')}.csv" }
    end
  end
end
