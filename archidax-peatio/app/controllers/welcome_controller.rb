# encoding: UTF-8
# frozen_string_literal: true

class WelcomeController < ApplicationController
  layout 'landing'
  layout 'marketcap', only: [:marketcap, :overview ]
  include Concerns::DisableCabinetUI

  def index
  	redirect_to '/accounts/sign_in' unless current_user 
  end

  def marketcap
  end

  def overview
  end
end
