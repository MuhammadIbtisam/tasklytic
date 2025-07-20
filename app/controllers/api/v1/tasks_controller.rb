module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!
      # before_action :set_task, only: [:show, :update, :destroy]

      def index
        page = params[:page].to_i
        unless page.positive?

        end
      end

    end
  end
end