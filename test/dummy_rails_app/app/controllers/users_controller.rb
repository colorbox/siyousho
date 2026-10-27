class UsersController < ApplicationController
  def new
  end

  def create
    # Simulate successful user creation
    redirect_to user_dashboard_path, notice: "Welcome! You have signed up successfully."
  end

  def dashboard
  end
end