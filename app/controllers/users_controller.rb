# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, only: %i[show index]
  def show
    @posts = current_user.posts.order('created_at desc')
  end

  def index
    @users = User.all
  end
end
