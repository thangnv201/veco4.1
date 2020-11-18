#!/bin/env ruby
# encoding: utf-8
class GmanagersController < ApplicationController
  unloadable
  include TaskReportsHelper
  include ProjectsHelper

  before_action :find_project, :authorize

  def find_project
    @project = Project.find(params["project_id"])
  end

  def index
    @project = Project.find(params[:project_id])
    @groups = Gmanager.getAll(params[:project_id])
  end

  def create
    error = ''
    if Gmanager.create_group(params["project_id"], params["groupname"], session['user_id'])
      error = "Group with the same name already exists"
    end
    respond_to do |format|
      format.html { redirect_to gmanagers_path(:project_id => @project, :error => error) }
    end
  end

  def new
    @project = Project.find(params[:project_id])
  end

  def show
    @project = Project.find(params[:project_id])
    #only one group not all of them
    @group = Gmanager.get_group_users(params["id"])
  end

  def edit
    @project = Project.find(params[:project_id])
    @group = Gmanager.get_group_users(params["id"])

    #@all_users = Gmanager.get_all_project_users(params[:project_id], params["id"])
    @all_users = get_all_project_users()

  end

  def update

    @project = Project.where(:identifier => params['project_id']).first
    @group = Group.find(params["id"])
    temp = params["edit"]

    #render error if user try to change something without permissions
    if (Gmanager.is_admin_group(params["id"]) and not Gmanager.may_user_do(params['project_id'], session["user_id"], :change_admin_groups)) or (not Gmanager.is_owner(params["id"], session["user_id"]) and not Gmanager.may_user_do(params["project_id"], session["user_id"], :change_other_groups))
      respond_to do |format|
        format.html { redirect_to gmanagers_path(:project_id => @project.id, :error => "You've got no rights for managing this group") and return }
      end
    end

    case temp
    when "group_name"
      res = Gmanager.update_name(params["id"], params["groupname"])
      if res
        respond_to do |format|
          format.html { redirect_to edit_gmanager_path(:project_id => @project.id, :id => params["id"]) }
        end
      else
        respond_to do |format|
          #format.html {render :action => "edit", :error=>"Группа с таким именем уже существут"}
          format.html { redirect_to gmanagers_path(:project_id => @project.id, :error => "Group with the same name already exists") }
        end
      end
    when "add_user"
      if params["user_select"]
        users = User.where(:id => params["user_select"])
        @group.users << users
        respond_to do |format|
          format.html { redirect_to edit_gmanager_path(:project_id => @project.id, :id => params["id"]) }
        end
      else
        respond_to do |format|
          format.html { redirect_to edit_gmanager_path(:project_id => @project.id, :id => params["id"], :error => "You must choose users to add") }
        end

      end
    when "del_user"
      #@group.users.delete(User.find(params["user"]))
      Gmanager.delete_user_from_group(params["user"], params["group"])
      respond_to do |format|
        format.html { redirect_to edit_gmanager_path(:project_id => @project.id, :id => params["group"]) }
      end

    when "change_owner"
      if Gmanager.may_user_do(params['project_id'], session['user_id'], :change_owner)
        Gmanager.change_owner(params['id'], params['owner'])
        respond_to do |format|
          format.html { redirect_to edit_gmanager_path(:project_id => @project.id, :id => params["id"]) }
        end
      end

    end
  end

#empty controllers action
  def update_admin

  end

#empty controllers action
  def delete_admin

  end

  def destroy
    @project = Project.find(params[:project_id])

    #check if user try to change admin created group
    if Gmanager.is_admin_group(params["id"]) and not Gmanager.may_user_do(@project, session["user_id"], :delete_admin_groups) or not Gmanager.is_owner(params["id"], session["user_id"]) and not Gmanager.may_user_do(@project, session["user_id"], :delete_other_groups)
      respond_to do |format|
        format.html { redirect_to gmanagers_path(:project_id => @project, :error => "You have not enough rights to delete this group") and return }
      end
    end

    Gmanager.delete_group(params["project_id"], params["id"])
    respond_to do |format|
      format.html { redirect_to gmanagers_path(:project_id => @project) }
    end
  end

  private

  def get_all_project_users()

    res = {}
    user_list_ids = @project.members.pluck(:user_id)
    user_list_ids.each do |user_id|
      begin
        res[user_id] = User.find(user_id).login
      rescue ActiveRecord::RecordNotFound => e

      end
    end
    res
  end

  def get_roles_config
    role_list = []
    begin
      xml_config_file = File.open("config/config.xml")
      data = Hash.from_xml(xml_config_file)
      role_list = data["config"]["kpi_ranking"]["role_config"]

      xml_config_file.close unless xml_config_file.closed?

    rescue Exception => ex
      Rails.logger.info "Cannot read config file to get role list" + ex.message
    end

    role_list
  end
end
