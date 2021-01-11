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

class IssuesController < ApplicationController
  default_search_scope :issues

  before_action :find_issue, :only => [:show, :edit, :update, :issue_tab]
  before_action :find_issues, :only => [:bulk_edit, :bulk_update, :destroy]
  before_action :authorize, :except => [:index, :new, :create]
  before_action :find_optional_project, :only => [:index, :new, :create]
  before_action :build_new_issue_from_params, :only => [:new, :create]
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :timelog

  $base_url ="http://localhost:9001"
  $customfield_id=74
  def index
    use_session = !request.format.csv?
    retrieve_query(IssueQuery, use_session)

    if @query.valid?
      respond_to do |format|
        format.html {
          @issue_count = @query.issue_count
          @issue_pages = Paginator.new @issue_count, per_page_option, params['page']
          @issues = @query.issues(:offset => @issue_pages.offset, :limit => @issue_pages.per_page)
          render :layout => !request.xhr?
        }
        format.api {
          @offset, @limit = api_offset_and_limit
          @query.column_names = %w(author)
          @issue_count = @query.issue_count
          @issues = @query.issues(:offset => @offset, :limit => @limit)
          Issue.load_visible_relations(@issues) if include_in_api_response?('relations')
        }
        format.atom {
          @issues = @query.issues(:limit => Setting.feeds_limit.to_i)
          render_feed(@issues, :title => "#{@project || Setting.app_title}: #{l(:label_issue_plural)}")
        }
        format.csv {
          @issues = @query.issues(:limit => Setting.issues_export_limit.to_i)
          send_data(query_to_csv(@issues, @query, params[:csv]), :type => 'text/csv; header=present', :filename => 'issues.csv')
        }
        format.pdf {
          @issues = @query.issues(:limit => Setting.issues_export_limit.to_i)
          send_file_headers! :type => 'application/pdf', :filename => 'issues.pdf'
        }
      end
    else
      respond_to do |format|
        format.html { render :layout => !request.xhr? }
        format.any(:atom, :csv, :pdf) { head 422 }
        format.api { render_validation_errors(@query) }
      end
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def show
    @journals = @issue.visible_journals_with_index
    @has_changesets = @issue.changesets.visible.preload(:repository, :user).exists?
    @relations = @issue.relations.select { |r| r.other_issue(@issue) && r.other_issue(@issue).visible? }

    @journals.reverse! if User.current.wants_comments_in_reverse_order?

    if User.current.allowed_to?(:view_time_entries, @project)
      Issue.load_visible_spent_hours([@issue])
      Issue.load_visible_total_spent_hours([@issue])
    end

    respond_to do |format|
      format.html {
        @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
        @priorities = IssuePriority.active
        @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
        @time_entries = @issue.time_entries.visible.preload(:activity, :user)
        @relation = IssueRelation.new
        retrieve_previous_and_next_issue_ids
        render :template => 'issues/show'
      }
      format.api {
        @changesets = @issue.changesets.visible.preload(:repository, :user).to_a
        @changesets.reverse! if User.current.wants_comments_in_reverse_order?
      }
      format.atom { render :template => 'journals/index', :layout => false, :content_type => 'application/atom+xml' }
      format.pdf {
        send_file_headers! :type => 'application/pdf', :filename => "#{@project.identifier}-#{@issue.id}.pdf"
      }
    end
  end

  def new
    respond_to do |format|
      format.html { render :action => 'new', :layout => !request.xhr? }
      format.js
    end
  end

  def create
    unless User.current.allowed_to?(:add_issues, @issue.project, :global => true)
      raise ::Unauthorized
    end
    call_hook(:controller_issues_new_before_save, {:params => params, :issue => @issue})
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    if @issue.save
      call_hook(:controller_issues_new_after_save, {:params => params, :issue => @issue})
      if @issue.author_id != @issue.assigned_to_id
        noticeArr=[]
        noticeArr.push("[VECO##{@issue.id}] #{@issue.status.name} | #{@issue.tracker.name}: #{@issue.subject}. Đ/c truy cập địa chỉ http://plm.vht.vn/issues/#{@issue.id} để xử lý!")
        handle_send_sms(@issue, noticeArr, 2)
      end
      respond_to do |format|
        format.html {
          render_attachment_warning_if_needed(@issue)
          flash[:notice] = l(:notice_issue_successful_create, :id => view_context.link_to("##{@issue.id}", issue_path(@issue), :title => @issue.subject))
          redirect_after_create
        }
        format.api { render :action => 'show', :status => :created, :location => issue_url(@issue) }
      end
      return
    else
      respond_to do |format|
        format.html {
          if @issue.project.nil?
            render_error :status => 422
          else
            render :action => 'new'
          end
        }
        format.api { render_validation_errors(@issue) }
      end
    end
  end

  def edit
    return unless update_issue_from_params

    respond_to do |format|
      format.html {}
      format.js
    end
  end

  def update
    changeStatus = false
    if @issue.status_id.to_i != params[:issue][:status_id].to_i
      changeStatus = true
    end
    #check status
    #
    begin
      if params[:issue][:status_id].to_i == 11
        url = $base_url + '/redmine-jbpm-intergration/api/v1/jbpm/task/status?issueid=' + @issue.id.to_s
        result = Net::HTTP.get(URI.parse(url))
        result_json = JSON.parse(result)
        if result_json["code"] == 1 && result_json["data"] != "SUCCESS" && result_json["data"] != "COMPLETED" && result_json["data"] != "COMPLETE"
          error = 'Yêu cầu đóng các task ' + result_json["data"].to_s + ' trước khi thực hiện submit task ' + @issue.id.to_s
          if request.format.json?
            render_api_errors([error])
          else
            flash[:error] = error
            redirect_to({:controller => 'issues', :action => 'edit', :id => @issue.id})
          end
          return
        end
      end
    rescue => err
      logger.info("QLQT Loi check trang thai quy trinh")
      logger.fatal(err)
      return
    end
    #
    return unless update_issue_from_params
    @issue.save_attachments(params[:attachments] || (params[:issue] && params[:issue][:uploads]))
    saved = false
    begin
      saved = save_issue_with_child_records
    rescue ActiveRecord::StaleObjectError
      @conflict = true
      if params[:last_journal_id]
        @conflict_journals = @issue.journals_after(params[:last_journal_id]).to_a
        @conflict_journals.reject!(&:private_notes?) unless User.current.allowed_to?(:view_private_notes, @issue.project)
      end
    end

    if saved
      render_attachment_warning_if_needed(@issue)
      flash[:notice] = l(:notice_successful_update) unless @issue.current_journal.new_record? || params[:no_flash]
      completeIssue(@issue)
      #sms
      begin
        @issueName = IssueStatuse.where(id: params[:issue][:status_id].to_i)
        trackerName = Tracker.where(id: @issue.tracker_id)

        if (@issue.id != params[:id].to_i || changeStatus)
          noticeArr = []
          if (trackerName[0].name == "KPIs" || trackerName[0].name == "OKRs" || trackerName[0].name == "Key Result")
            if (params[:issue][:status_id].to_i == 20)
              #Status Yeu cau cap nhat
              noticeArr.push("[VECO##{@issue.id}] Văn phòng ĐỀ NGHỊ Đ/C CẬP NHẬT #{trackerName[0].name}: #{@issue.subject} tại địa chỉ http://plm.vht.vn/issues/#{@issue.id}. Trân trọng cảm ơn!")
              handle_send_sms(@issue, noticeArr, 3)
            end
            if (params[:issue][:status_id].to_i == 22)
              #Status Hoan thanh cap nhat
              noticeArr.push("[VECO##{@issue.id}] Văn phòng ĐỀ NGHỊ Đ/C PHÊ DUYỆT nội dung #{trackerName[0].name}: #{@issue.subject} tại địa chỉ http://plm.vht.vn/issues/#{@issue.id}. Trân trọng cảm ơn!")
              handle_send_sms(@issue, noticeArr, 4)
            end
          elsif (trackerName[0].name == "KPIs - Định lượng" || trackerName[0].name == "KPIs - Thời hạn" || trackerName[0].name == "KPIs - Định mức")
            if (params[:issue][:status_id].to_i == 32)
              noticeArr.push("[KPI##{@issue.id}] #{@issue.subject} đã được thống nhất.")
              handle_send_sms(@issue, noticeArr, 5)
            end
            if (params[:issue][:status_id].to_i == 34)
              noticeArr.push("[KPI##{@issue.id}] #{@issue.subject} đã được QLTT đánh giá.")
              handle_send_sms(@issue, noticeArr, 5)
            end
            if (params[:issue][:status_id].to_i == 35)
              noticeArr.push("Đồng chí đã hủy KPI##{@issue.id} #{@issue.subject}.")
              handle_send_sms(@issue, noticeArr, 5)
              noticeAuthor = []
              noticeAuthor.push("CBNV #{User.current.login} đã hủy KPI##{@issue.id} #{@issue.subject}.")
              handle_send_sms(@issue, noticeAuthor, 6)
            end
          else
            #Other tracker
            noticeArr.push("[VECO##{@issue.id}] #{@issueName[0].name} | #{trackerName[0].name}: #{@issue.subject}. Đ/c truy cập địa chỉ http://plm.vht.vn/issues/#{@issue.id} để xử lý!")
            if (params[:issue][:status_id].to_i == 15 || params[:issue][:status_id].to_i == 19 || params[:issue][:status_id].to_i == 17)
              handle_send_sms(@issue, noticeArr, 1)
            end
            if (params[:issue][:status_id].to_i == 11 || params[:issue][:status_id].to_i == 14 || params[:issue][:status_id].to_i == 12 || params[:issue][:status_id].to_i == 18 || params[:issue][:status_id].to_i == 20 || params[:issue][:status_id].to_i == 21 || params[:issue][:status_id].to_i == 22)
              handle_send_sms(@issue, noticeArr, 2)
            end
          end
        end
      rescue => err
        logger.info("SMS: Khong gui duoc tin nhan khi cho duyet, duoc duyet Issue")
        logger.fatal(err)
      end
      respond_to do |format|
        format.html { redirect_back_or_default issue_path(@issue, previous_and_next_issue_ids_params) }
        format.api { render_api_ok }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
        format.api { render_validation_errors(@issue) }
      end
    end
  end

  def issue_tab
    return render_error :status => 422 unless request.xhr?
    tab = params[:name]

    case tab
    when 'time_entries'
      @time_entries = @issue.time_entries.visible.preload(:activity, :user).to_a
      render :partial => 'issues/tabs/time_entries', :locals => {:time_entries => @time_entries}
    when 'changesets'
      @changesets = @issue.changesets.visible.preload(:repository, :user).to_a
      @changesets.reverse! if User.current.wants_comments_in_reverse_order?
      render :partial => 'issues/tabs/changesets', :locals => {:changesets => @changesets}
    end
  end

  # Bulk edit/copy a set of issues
  def bulk_edit
    @issues.sort!
    @copy = params[:copy].present?
    @notes = params[:notes]

    if @copy
      unless User.current.allowed_to?(:copy_issues, @projects)
        raise ::Unauthorized
      end
    else
      unless @issues.all?(&:attributes_editable?)
        raise ::Unauthorized
      end
    end

    edited_issues = Issue.where(:id => @issues.map(&:id)).to_a

    @values_by_custom_field = {}
    edited_issues.each do |issue|
      issue.custom_field_values.each do |c|
        if c.value_present?
          @values_by_custom_field[c.custom_field] ||= []
          @values_by_custom_field[c.custom_field] << issue.id
        end
      end
    end

    @allowed_projects = Issue.allowed_target_projects
    if params[:issue]
      @target_project = @allowed_projects.detect { |p| p.id.to_s == params[:issue][:project_id].to_s }
      if @target_project
        target_projects = [@target_project]
        edited_issues.each { |issue| issue.project = @target_project }
      end
    end
    target_projects ||= @projects

    @trackers = target_projects.map { |p| Issue.allowed_target_trackers(p) }.reduce(:&)
    if params[:issue]
      @target_tracker = @trackers.detect { |t| t.id.to_s == params[:issue][:tracker_id].to_s }
      if @target_tracker
        edited_issues.each { |issue| issue.tracker = @target_tracker }
      end
    end

    if @copy
      # Copied issues will get their default statuses
      @available_statuses = []
    else
      @available_statuses = edited_issues.map(&:new_statuses_allowed_to).reduce(:&)
    end
    if params[:issue]
      @target_status = @available_statuses.detect { |t| t.id.to_s == params[:issue][:status_id].to_s }
      if @target_status
        edited_issues.each { |issue| issue.status = @target_status }
      end
    end

    edited_issues.each do |issue|
      issue.custom_field_values.each do |c|
        if c.value_present? && @values_by_custom_field[c.custom_field]
          @values_by_custom_field[c.custom_field].delete(issue.id)
        end
      end
    end
    @values_by_custom_field.delete_if { |k, v| v.blank? }

    @custom_fields = edited_issues.map { |i| i.editable_custom_fields }.reduce(:&).select { |field| field.format.bulk_edit_supported }
    @assignables = target_projects.map(&:assignable_users).reduce(:&)
    @versions = target_projects.map { |p| p.shared_versions.open }.reduce(:&)
    @categories = target_projects.map { |p| p.issue_categories }.reduce(:&)
    if @copy
      @attachments_present = @issues.detect { |i| i.attachments.any? }.present?
      @subtasks_present = @issues.detect { |i| !i.leaf? }.present?
      @watchers_present = User.current.allowed_to?(:add_issue_watchers, @projects) &&
          Watcher.where(:watchable_type => 'Issue',
                        :watchable_id => @issues.map(&:id)).exists?
    end

    @safe_attributes = edited_issues.map(&:safe_attribute_names).reduce(:&)

    @issue_params = params[:issue] || {}
    @issue_params[:custom_field_values] ||= {}
  end

  def bulk_update
    @issues.sort!
    @copy = params[:copy].present?

    attributes = parse_params_for_bulk_update(params[:issue])
    copy_subtasks = (params[:copy_subtasks] == '1')
    copy_attachments = (params[:copy_attachments] == '1')
    copy_watchers = (params[:copy_watchers] == '1')

    if @copy
      unless User.current.allowed_to?(:copy_issues, @projects)
        raise ::Unauthorized
      end
      target_projects = @projects
      if attributes['project_id'].present?
        target_projects = Project.where(:id => attributes['project_id']).to_a
      end
      unless User.current.allowed_to?(:add_issues, target_projects)
        raise ::Unauthorized
      end
      unless User.current.allowed_to?(:add_issue_watchers, @projects)
        copy_watchers = false
      end
    else
      unless @issues.all?(&:attributes_editable?)
        raise ::Unauthorized
      end
    end

    unsaved_issues = []
    saved_issues = []

    if @copy && copy_subtasks
      # Descendant issues will be copied with the parent task
      # Don't copy them twice
      @issues.reject! { |issue| @issues.detect { |other| issue.is_descendant_of?(other) } }
    end

    @issues.each do |orig_issue|
      orig_issue.reload
      if @copy
        issue = orig_issue.copy(
            {},
            :attachments => copy_attachments,
            :subtasks => copy_subtasks,
            :watchers => copy_watchers,
            :link => link_copy?(params[:link_copy])
        )
      else
        issue = orig_issue
      end
      journal = issue.init_journal(User.current, params[:notes])
      issue.safe_attributes = attributes
      call_hook(:controller_issues_bulk_edit_before_save, {:params => params, :issue => issue})
      if issue.save
        completeIssue(issue)
        saved_issues << issue
      else
        unsaved_issues << orig_issue
      end
    end

    if unsaved_issues.empty?
      flash[:notice] = l(:notice_successful_update) unless saved_issues.empty?
      if params[:follow]
        if @issues.size == 1 && saved_issues.size == 1
          redirect_to issue_path(saved_issues.first)
        elsif saved_issues.map(&:project).uniq.size == 1
          redirect_to project_issues_path(saved_issues.map(&:project).first)
        end
      else
        redirect_back_or_default _project_issues_path(@project)
      end
    else
      @saved_issues = @issues
      @unsaved_issues = unsaved_issues
      @issues = Issue.visible.where(:id => @unsaved_issues.map(&:id)).to_a
      bulk_edit
      render :action => 'bulk_edit'
    end
  end

  def destroy
    raise Unauthorized unless @issues.all?(&:deletable?)

    # all issues and their descendants are about to be deleted
    issues_and_descendants_ids = Issue.self_and_descendants(@issues).pluck(:id)
    time_entries = TimeEntry.where(:issue_id => issues_and_descendants_ids)
    @hours = time_entries.sum(:hours).to_f

    if @hours > 0
      case params[:todo]
      when 'destroy'
        # nothing to do
      when 'nullify'
        if Setting.timelog_required_fields.include?('issue_id')
          flash.now[:error] = l(:field_issue) + " " + ::I18n.t('activerecord.errors.messages.blank')
          return
        else
          time_entries.update_all(:issue_id => nil)
        end
      when 'reassign'
        reassign_to = @project && @project.issues.find_by_id(params[:reassign_to_id])
        if reassign_to.nil?
          flash.now[:error] = l(:error_issue_not_found_in_project)
          return
        elsif issues_and_descendants_ids.include?(reassign_to.id)
          flash.now[:error] = l(:error_cannot_reassign_time_entries_to_an_issue_about_to_be_deleted)
          return
        else
          time_entries.update_all(:issue_id => reassign_to.id, :project_id => reassign_to.project_id)
        end
      else
        # display the destroy form if it's a user request
        return unless api_request?
      end
    end
    @issues.each do |issue|
      begin
        issue.reload.destroy
      rescue ::ActiveRecord::RecordNotFound # raised by #reload if issue no longer exists
        # nothing to do, issue was already deleted (eg. by a parent)
      end
    end
    respond_to do |format|
      format.html { redirect_back_or_default _project_issues_path(@project) }
      format.api { render_api_ok }
    end
  end

  # Overrides Redmine::MenuManager::MenuController::ClassMethods for
  # when the "New issue" tab is enabled
  def current_menu_item
    if Setting.new_item_menu_tab == '1' && [:new, :create].include?(action_name.to_sym)
      :new_issue
    else
      super
    end
  end

  private

  def retrieve_previous_and_next_issue_ids
    if params[:prev_issue_id].present? || params[:next_issue_id].present?
      @prev_issue_id = params[:prev_issue_id].presence.try(:to_i)
      @next_issue_id = params[:next_issue_id].presence.try(:to_i)
      @issue_position = params[:issue_position].presence.try(:to_i)
      @issue_count = params[:issue_count].presence.try(:to_i)
    else
      retrieve_query_from_session
      if @query
        @per_page = per_page_option
        limit = 500
        issue_ids = @query.issue_ids(:limit => (limit + 1))
        if (idx = issue_ids.index(@issue.id)) && idx < limit
          if issue_ids.size < 500
            @issue_position = idx + 1
            @issue_count = issue_ids.size
          end
          @prev_issue_id = issue_ids[idx - 1] if idx > 0
          @next_issue_id = issue_ids[idx + 1] if idx < (issue_ids.size - 1)
        end
        query_params = @query.as_params
        if @issue_position
          query_params = query_params.merge(:page => (@issue_position / per_page_option) + 1, :per_page => per_page_option)
        end
        @query_path = _project_issues_path(@query.project, query_params)
      end
    end
  end

  def previous_and_next_issue_ids_params
    {
        :prev_issue_id => params[:prev_issue_id],
        :next_issue_id => params[:next_issue_id],
        :issue_position => params[:issue_position],
        :issue_count => params[:issue_count]
    }.reject { |k, v| k.blank? }
  end

  # Used by #edit and #update to set some common instance variables
  # from the params
  def update_issue_from_params
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end

    @issue.init_journal(User.current)

    issue_attributes = params[:issue]
    issue_attributes[:assigned_to_id] = User.current.id if issue_attributes && issue_attributes[:assigned_to_id] == 'me'
    if issue_attributes && params[:conflict_resolution]
      case params[:conflict_resolution]
      when 'overwrite'
        issue_attributes = issue_attributes.dup
        issue_attributes.delete(:lock_version)
      when 'add_notes'
        issue_attributes = issue_attributes.slice(:notes, :private_notes)
      when 'cancel'
        redirect_to issue_path(@issue)
        return false
      end
    end
    @issue.safe_attributes = issue_attributes
    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    true
  end

  # Used by #new and #create to build a new issue from the params
  # The new issue will be copied from an existing one if copy_from parameter is given
  def build_new_issue_from_params
    @issue = Issue.new
    if params[:copy_from]
      begin
        @issue.init_journal(User.current)
        @copy_from = Issue.visible.find(params[:copy_from])
        unless User.current.allowed_to?(:copy_issues, @copy_from.project)
          raise ::Unauthorized
        end
        @link_copy = link_copy?(params[:link_copy]) || request.get?
        @copy_attachments = params[:copy_attachments].present? || request.get?
        @copy_subtasks = params[:copy_subtasks].present? || request.get?
        @copy_watchers = User.current.allowed_to?(:add_issue_watchers, @project)
        @issue.copy_from(@copy_from, :attachments => @copy_attachments, :subtasks => @copy_subtasks, :watchers => @copy_watchers, :link => @link_copy)
        @issue.parent_issue_id = @copy_from.parent_id
      rescue ActiveRecord::RecordNotFound
        render_404
        return
      end
    end
    @issue.project = @project
    if request.get?
      @issue.project ||= @issue.allowed_target_projects.first
    end
    @issue.author ||= User.current
    @issue.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?

    attrs = (params[:issue] || {}).deep_dup
    if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
      attrs.delete(:status_id)
    end
    if action_name == 'new' && params[:form_update_triggered_by] == 'issue_project_id'
      # Discard submitted version when changing the project on the issue form
      # so we can use the default version for the new project
      attrs.delete(:fixed_version_id)
    end
    attrs[:assigned_to_id] = User.current.id if attrs[:assigned_to_id] == 'me'
    @issue.safe_attributes = attrs

    if @issue.project
      @issue.tracker ||= @issue.allowed_target_trackers.first
      if @issue.tracker.nil?
        if @issue.project.trackers.any?
          # None of the project trackers is allowed to the user
          render_error :message => l(:error_no_tracker_allowed_for_new_issue_in_project), :status => 403
        else
          # Project has no trackers
          render_error l(:error_no_tracker_in_project)
        end
        return false
      end
      if @issue.status.nil?
        render_error l(:error_no_default_issue_status)
        return false
      end
    elsif request.get?
      render_error :message => l(:error_no_projects_with_tracker_allowed_for_new_issue), :status => 403
      return false
    end

    @priorities = IssuePriority.active
    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
  end

  # Saves @issue and a time_entry from the parameters
  def save_issue_with_child_records
    Issue.transaction do
      if params[:time_entry] && (params[:time_entry][:hours].present? || params[:time_entry][:comments].present?) && User.current.allowed_to?(:log_time, @issue.project)
        time_entry = @time_entry || TimeEntry.new
        time_entry.project = @issue.project
        time_entry.issue = @issue
        time_entry.author = User.current
        time_entry.user = User.current
        time_entry.spent_on = User.current.today
        time_entry.safe_attributes = params[:time_entry]
        @issue.time_entries << time_entry
      end

      call_hook(:controller_issues_edit_before_save, {:params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
      if @issue.save
        call_hook(:controller_issues_edit_after_save, {:params => params, :issue => @issue, :time_entry => time_entry, :journal => @issue.current_journal})
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  # Returns true if the issue copy should be linked
  # to the original issue
  def link_copy?(param)
    case Setting.link_copied_issue
    when 'yes'
      true
    when 'no'
      false
    when 'ask'
      param == '1'
    end
  end

  # Redirects user after a successful issue creation
  def redirect_after_create
    if params[:continue]
      url_params = {}
      url_params[:issue] = {:tracker_id => @issue.tracker, :parent_issue_id => @issue.parent_issue_id}.reject { |k, v| v.nil? }
      url_params[:back_url] = params[:back_url].presence

      if params[:project_id]
        redirect_to new_project_issue_path(@issue.project, url_params)
      else
        url_params[:issue].merge! :project_id => @issue.project_id
        redirect_to new_issue_path(url_params)
      end
    else
      redirect_back_or_default issue_path(@issue)
    end
  end

  DB_HOST = "10.60.19.18"
  DB_USER = "hrmuser"
  DB_PASSWORD = "123456a@"
  DB = "smssupport"

  def handle_sendSMS(phone_array, content)
    # client = Mysql2::Client.new(:host => DB_HOST, :username => DB_USER,
    #                             :password => DB_PASSWORD, :database => DB)
    #
    # phone_array.each_with_index do |user, index|
    #   phone = '84'.dup << user.phone[1..-1].dup
    #   insert = client.query("INSERT INTO sms (phone, content, sent)
    #                      VALUES ('#{phone}', '#{content[index]}','#{0}')")
    #   client.close
    # end
  end

  def handle_send_sms (issue, noticeArr, status)
    # if (Setting.environment != 2)
    #   return
    # end

    if status == 1
      #start test
      project = Project.find(issue.project_id)
      @user = []
      roles_receiver = project.custom_field_values.select { |obj| obj.custom_field.name == "SMS Receiver" }.first.value

      roles_receiver.each do |role_name|
        if role_name == "* Trưởng nhóm"
          #Lay group cua project

          group_ids = Member.joins(:principal).where(:project_id => project.id).where(:users => {:type => "Group"}).map(&:user_id)
          group_ids.each do |group_id|

            group_member_ids = User.in_group(group_id).map(&:id)
            if (group_member_ids.include? issue.assigned_to_id)
              #Tim truong nhom
              owner_id = Gmanager.where(:id_group => group_id).first.id_owner
              @user << User.find(owner_id);
            end
          end
          if @user.length == 0
            #Lay tat ca user co role truong nhom neu ko tim thay group
            Member.joins(:roles).where("#{Role.table_name}.name" => role_name).where(:project_id => project.id).each do |member|
              @user << User.find(member.user_id)
            end
          end
        else
          Member.joins(:roles).where("#{Role.table_name}.name" => role_name).where(:project_id => project.id).each do |member|
            @user << User.find(member.user_id)
          end
        end
      end
      @user = @user.uniq

      #end test
      @user.each do |userPM|
        @userSMS = VecoPhone.where(name: userPM.login)
        if issue.assigned_to_id != userPM.id
          handle_sendSMS(@userSMS, noticeArr)
        end
      end
    end

    if status == 2
      (User.where(id: issue.assigned_to_id)).each do |getUser|
        @userSMS = VecoPhone.where(name: getUser.login)
        handle_sendSMS(@userSMS, noticeArr)
      end
    end

    if status == 3
      #Trang thai: Yêu cầu cập nhật (issue status 20)
      (User.where(id: issue.assigned_to_id)).each do |getUser|
        @userSMS = VecoPhone.where(name: getUser.login)
        handle_sendSMS(@userSMS, noticeArr)
      end
    end
    if status == 4
      #Trang thai: Hoàn thành cập nhật (issue status 22)
      idPM = issue.custom_value_for(81).value
      loginPM = User.where(id: idPM).first.login
      @userSMS = VecoPhone.where(name: loginPM)
      handle_sendSMS(@userSMS, noticeArr)
    end
    if status == 5
      # KPI gui CBNV
      (User.where(id: issue.assigned_to_id)).each do |getUser|
        @userSMS = VecoPhone.where(name: getUser.login)
        handle_sendSMS(@userSMS, noticeArr)
      end
    end
    if status == 6
      # KPI GUI QLTT
      (User.where(id: issue.author_id)).each do |getUser|
        @userSMS = VecoPhone.where(name: getUser.login)
        handle_sendSMS(@userSMS, noticeArr)
      end
    end
  end

  def completeIssue(issue)
    byebug
    if issue.status_id.to_int == 11
      begin
        checkWorkFollow = issue.custom_field_value($customfield_id);

        if (checkWorkFollow == "1. Đạt")
          checkWorkFollow = "-Y";
        elsif (checkWorkFollow == "2. Không đạt")
          checkWorkFollow = "-N";
        end
        uri = URI.parse($base_url + "/redmine-jbpm-intergration/api/v1/jbpm/task/complete?issueid=" + issue.id.to_s + "&key=25304089a591cf457f3a6d1073e405d980133d94")
        header = {'Content-Type': 'application/json; charset=utf-8'}
        data = {"taskContent": "", "branch": issue.status_id.to_s + checkWorkFollow, "projectCode": issue.project_id}
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.body = data.to_json
        response = http.request(request)
        logger.info(response)
      rescue => err
        logger.fatal(err)
      end
    end
  end

end
