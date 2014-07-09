class AboutController < ApplicationController
  def show
    add_breadcrumb t('home'), :root_path
    add_breadcrumb t('about_us')

    @designers = Designer.all
    @introduce_image_slides = IntroduceImageSlide.all
    @introduce_youtubes = IntroduceYoutube.all
    @contact_us = ContactUs.new
    @faqs = Faq.where(locale_id: session[:locale_id]).order(:id)
  end
end
