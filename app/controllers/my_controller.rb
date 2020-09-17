# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2019  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class MyController < ApplicationController
  self.main_menu = false
  before_action :require_login
  # let user change user's password when user has to
  skip_before_action :check_password_change, :only => :password

  accept_api_auth :account

  require_sudo_mode :account, only: :put
  require_sudo_mode :reset_rss_key, :reset_api_key, :show_api_key, :destroy

  helper :issues
  helper :users
  helper :custom_fields
  helper :queries
  helper :activities
  helper :calendars

  def index
    page
    render :action => 'page'
  end

  # Show user's page
  def page
    Rails.logger.silence do
      @user = User.current
      @user = Person.find(User.current.id)
      @check_permission = User.current.roles.any? { |a| a.id == 17 || a.id == 12 || a.id == 4 }
      if @check_permission
        @issue_open_new = @user.assigned_issues.open.where(:status_id => 14).count
        @issue_open_doing = @user.assigned_issues.open.where(:status_id => 8).count
        @issue_open_review = @user.assigned_issues.open.where(:status_id => 15).count
        @total_issue_assigned = @issue_open_new + @issue_open_doing + @issue_open_review
        @task_overdate = @user.assigned_issues.open.where('due_date < ?', User.current.today).count
        @task_high_priority = @user.assigned_issues.open.where('priority_id = ?', 3).count
        @task_complete_in_month = @user.assigned_issues.where(:status_id => 11)
                                      .where(:closed_on => User.current.today.at_beginning_of_month..User.current.today.at_end_of_month).count
        @task_complete_in_month_before_one = @user.assigned_issues
                                                 .where(:status_id => 11).where(:closed_on => (User.current.today - 1.month).at_beginning_of_month..(User.current.today - 1.month).at_end_of_month).count
        @task_complete_in_month_before_two = @user.assigned_issues
                                                 .where(:status_id => 11).where(:closed_on => (User.current.today - 2.month).at_beginning_of_month..(User.current.today - 2.month).at_end_of_month).count
        @task_complete_in_month_before_three = @user.assigned_issues
                                                   .where(:status_id => 11).where(:closed_on => (User.current.today - 3.month).at_beginning_of_month..(User.current.today - 3.month).at_end_of_month).count
        @task_complete_in_month_before_four = @user.assigned_issues
                                                  .where(:status_id => 11).where(:closed_on => (User.current.today - 4.month).at_beginning_of_month..(User.current.today - 4.month).at_end_of_month).count
      end
      #my kpi
      @kpi_open = @user.assigned_issues.where(:tracker_id => [39, 40, 41]).open.where.not(:status_id => 35).count
      @kpi_cbnv_open = Project.find(1072).issues.where(:author_id =>User.current.id).open.where.not(:status_id => 35).count

      byebug
      @groups = @user.pref.my_page_groups
      @blocks = @user.pref.my_page_layout
    end

  end

  def count_kpi_by_status(list_user, status_id)
    count = 0
    list_user.each do |people|
      count += people.assigned_issues.where(:tracker_id => [39, 40, 41]).where(:status_id => status_id).count
    end
    count
  end

  # Edit user's account
  def account
    byebug
    @user = User.current
    @pref = @user.pref
    if request.put?
      @user.safe_attributes = params[:user]
      @user.pref.safe_attributes = params[:pref]
      if @user.save
        @user.pref.save
        set_language_if_valid @user.language
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_account_updated)
            redirect_to my_account_path
          }
          format.api { render_api_ok }
        end
        return
      else
        respond_to do |format|
          format.html { render :action => :account }
          format.api { render_validation_errors(@user) }
        end
      end
    end
  end

  # Destroys user's account
  def destroy
    @user = User.current
    unless @user.own_account_deletable?
      redirect_to my_account_path
      return
    end

    if request.post? && params[:confirm]
      @user.destroy
      if @user.destroyed?
        logout_user
        flash[:notice] = l(:notice_account_deleted)
      end
      redirect_to home_path
    end
  end

  # Manage user's password
  def password
    @user = User.current
    unless @user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to my_account_path
      return
    end
    if request.post?
      if !@user.check_password?(params[:password])
        flash.now[:error] = l(:notice_account_wrong_password)
      elsif params[:password] == params[:new_password]
        flash.now[:error] = l(:notice_new_password_must_be_different)
      else
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        @user.must_change_passwd = false
        if @user.save
          # The session token was destroyed by the password change, generate a new one
          session[:tk] = @user.generate_session_token
          Mailer.deliver_password_updated(@user, User.current)
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to my_account_path
        end
      end
    end
  end

  # Create a new feeds key
  def reset_rss_key
    if request.post?
      if User.current.rss_token
        User.current.rss_token.destroy
        User.current.reload
      end
      User.current.rss_key
      flash[:notice] = l(:notice_feeds_access_key_reseted)
    end
    redirect_to my_account_path
  end

  def show_api_key
    @user = User.current
  end

  # Create a new API key
  def reset_api_key
    if request.post?
      if User.current.api_token
        User.current.api_token.destroy
        User.current.reload
      end
      User.current.api_key
      flash[:notice] = l(:notice_api_access_key_reseted)
    end
    redirect_to my_account_path
  end

  def update_page
    @user = User.current
    block_settings = params[:settings] || {}

    block_settings.each do |block, settings|
      @user.pref.update_block_settings(block, settings.to_unsafe_hash)
    end
    @user.pref.save
    @updated_blocks = block_settings.keys
  end

  # Add a block to user's page
  # The block is added on top of the page
  # params[:block] : id of the block to add
  def add_block
    @user = User.current
    @block = params[:block]
    if @user.pref.add_block @block
      @user.pref.save
      respond_to do |format|
        format.html { redirect_to my_page_path }
        format.js
      end
    else
      render_error :status => 422
    end
  end

  # Remove a block to user's page
  # params[:block] : id of the block to remove
  def remove_block
    @user = User.current
    @block = params[:block]
    @user.pref.remove_block @block
    @user.pref.save
    respond_to do |format|
      format.html { redirect_to my_page_path }
      format.js
    end
  end

  # Change blocks order on user's page
  # params[:group] : group to order (top, left or right)
  # params[:blocks] : array of block ids of the group
  def order_blocks
    @user = User.current
    @user.pref.order_blocks params[:group], params[:blocks]
    @user.pref.save
    head 200
  end
end
