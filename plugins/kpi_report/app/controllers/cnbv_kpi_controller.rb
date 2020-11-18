class CnbvKpiController < ApplicationController
  include CnbvKpiHelper

  $kidanhgia = Project.find(1072).default_version_id

  def index
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    $pmid = User.current.id
    $alluser = User.where(status: 1).select(:id)
    @kpi_raking = PeopleInformation.where(manager_id: $pmid, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def sub_dep_ki
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    if params.key?("sub_dep")
      @sub_dep = params["sub_dep"].to_i == 1 ? true : false
    else
      @sub_dep = false
    end
    $dpid = Department.where(head_id: User.current.id).select(:id).map(&:id).uniq
    if @sub_dep
      Department.where(:id => $dpid).each do |dep|
        $dpid += Department.where('lft >? and rgt <?', dep.lft, dep.rgt).select(:id).map(&:id).uniq
      end
    end

    $alluser = User.where(status: 1).where.not(login: User.current.login).select(:id)
    @kpi_raking = PeopleInformation.where(department_id: $dpid, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end

  end

  def dep_ki
    if User.current.allowed_people_to?(:submit_ki, @person)
      if params.key?("kidanhgia")
        $kidanhgia = params["kidanhgia"].to_i
      else
        $kidanhgia = Project.find(1072).default_version_id
      end
      $dids = []
      @department_id = Department.where(head_id: User.current.id)
      @department_id.each do |dep|
        $dids.push(dep.id)
        lft = Department.find(dep.id).lft
        rgt = Department.find(dep.id).rgt
        @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
        @ids.each do |obj|
          $dids.push(obj.id)
        end
      end
      $alluser = User.where(status: 1).where.not(login: User.current.login).select(:id)
      @kpi_raking = PeopleInformation.where(department_id: $dids, user_id: $alluser).order(:user_id)
      users_id = []
      @kpi_raking.each do |kpi|
        users_id.push(kpi.user_id)
      end
      if users_id.size == 0
        @ki_raking = nil
        @kpi_each = nil
      else
        sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
        @records_array = ActiveRecord::Base.connection.execute(sql)
        @ki_raking = @records_array.as_json
        @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
      end
    else
      render_403 :message => :notice_not_authorized
    end
  end

  def TCLD
    if User.current.allowed_people_to?(:manage_ki, @person)
      if params.key?("kidanhgia")
        $kidanhgia = params["kidanhgia"].to_i
      else
        $kidanhgia = Project.find(1072).default_version_id
      end
      $pmid = PeopleInformation.where.not(manager_id: nil).select(:manager_id).map(&:manager_id).uniq.first
      if params.key?("manager")
        $pmid = params["manager"].to_i
      else
        $pmid = PeopleInformation.where.not(manager_id: nil).select(:manager_id).map(&:manager_id).uniq.first
      end
      $alluser = User.where(status: 1).select(:id)
      @kpi_raking = PeopleInformation.where(manager_id: $pmid, user_id: $alluser).order(:user_id)
      users_id = []
      @kpi_raking.each do |kpi|
        users_id.push(kpi.user_id)
      end
      if users_id.size == 0
        @ki_raking = nil
        @kpi_each = nil
      else
        sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
        @records_array = ActiveRecord::Base.connection.execute(sql)
        @ki_raking = @records_array.as_json
        @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
      end
    else
      render_403 :message => :notice_not_authorized
    end
  end

  def update_to_tracker(version)
    # Group.find(1839).user_ids.each do |id|
    $dpmid = Department.where(ki_confirm: 1).first.id
    if params.key?("dpmid")
      $dpmid = params["dpmid"].to_i
    else
      $dpmid = Department.where(ki_confirm: 1).first.id
    end
    h_id = Department.find($dpmid).head_id
    PeopleInformation.where(department_id: $dpmid).select(:user_id).each do |id|
      issue = Issue.where(:assigned_to_id => id).where(:fixed_version_id => version).where(:tracker_id => 51).first
      if !issue.nil?
        people_ki = PeopleKi.where(:user_id => id).where(:version_id => version).first
        if people_ki.nil?
          next
        end
        if people_ki.flag == 0
          point = people_ki.kpi
          location = people_ki.location_compliance == 1 ? 152 : people_ki.location_compliance == 2 ? 153 : 154
          labor = people_ki.labor_rules_compliance == 1 ? 155 : people_ki.labor_rules_compliance == 2 ? 156 : 157
          note = people_ki.note.nil? ? '' : people_ki.note
          manager_note = people_ki.manager_note.nil? ? '' : people_ki.manager_note
          department_name = CustomValue.where(customized_id: id, custom_field_id: 53).select(:value).take(1).nil? ? "" : CustomValue.where(customized_id: id, custom_field_id: 53).select(:value).take(1).first.value
          if !CustomFieldEnumeration.find_by_name(people_ki.ki).nil?
            ki = CustomFieldEnumeration.find_by_name(people_ki.ki).id unless people_ki.ki.nil?
          else
            ki = nil
          end
          issue.custom_field_values = {223 => point, 224 => location, 225 => labor, 227 => ki, 240 => note, 241 => manager_note, 242 => department_name}
          issue.save
          people_ki.flag = 1
          people_ki.save
        end
      else
        issue = Issue.new(
            :tracker_id => 51,
            :project_id => 1072,
            :subject => "KI CBNV",
            :status_id => 37,
            :assigned_to_id => id,
            :priority_id => 2,
            :fixed_version_id => version,
            :author_id => 1,
        )
        if issue.save
          people_ki = PeopleKi.where(:user_id => id).where(:version_id => version).first
          if people_ki.nil?
            next
          end
          if people_ki.flag == 0
            point = people_ki.kpi
            location = people_ki.location_compliance == 1 ? 152 : people_ki.location_compliance == 2 ? 153 : 154
            labor = people_ki.labor_rules_compliance == 1 ? 155 : people_ki.labor_rules_compliance == 2 ? 156 : 157
            note = people_ki.note.nil? ? '' : people_ki.note
            manager_note = people_ki.manager_note.nil? ? '' : people_ki.manager_note
            department_name = CustomValue.where(customized_id: id, custom_field_id: 53).select(:value).take(1).nil? ? "" : CustomValue.where(customized_id: id, custom_field_id: 53).select(:value).take(1).first.value
            if !CustomFieldEnumeration.find_by_name(people_ki.ki).nil?
              ki = CustomFieldEnumeration.find_by_name(people_ki.ki).id unless people_ki.ki.nil?
              people_ki.flag = 1
            else
              ki = nil
              people_ki.flag = 0
            end
            issue.custom_field_values = {223 => point, 224 => location, 225 => labor, 227 => ki, 240 => note, 241 => manager_note, 242 => department_name}
            issue.save
            people_ki.save
          end
        end
      end

    end
  end

  def tcld2
    if User.current.allowed_people_to?(:manage_ki, @person)
      $dpmid = Department.where(ki_confirm: 1).first.id
      if params.key?("dpmid")
        $dpmid = params["dpmid"].to_i
      else
        $dpmid = Department.where(ki_confirm: 1).first.id
      end
      if params.key?("kidanhgia")
        $kidanhgia = params["kidanhgia"].to_i
      else
        $kidanhgia = Project.find(1072).default_version_id
      end
      update_to_tracker($kidanhgia)
      $dids = []
      $dids.push($dpmid)
      lft = Department.find($dpmid).lft
      rgt = Department.find($dpmid).rgt
      @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
      @ids.each do |obj|
        $dids.push(obj.id)
      end
      $alluser = User.where(status: 1).select(:id)
      @kpi_raking = PeopleInformation.where(department_id: $dids, user_id: $alluser).order(:user_id)
      users_id = []
      @kpi_raking.each do |kpi|
        users_id.push(kpi.user_id)
      end
      if users_id.size == 0
        @ki_raking = nil
        @kpi_each = nil
      else
        sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
        @records_array = ActiveRecord::Base.connection.execute(sql)
        @ki_raking = @records_array.as_json
        @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
      end
    else
      render_403 :message => :notice_not_authorized
    end
  end

  def heads
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    if params.key?("headid")
      $pmid = params["headid"].to_i
    else
      $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    end
    $alluser = User.where(status: 1).select(:id)
    dids = []
    @department_id = Department.where(head_id: $pmid)
    @department_id.each do |dep|
      dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s)
      @ids.each do |obj|
        dids.push(obj.id)
      end
    end
    @kpi_raking = PeopleInformation.where(department_id: dids, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def heads2
    if params.key?("kidanhgia")
      $kidanhgia = params["kidanhgia"].to_i
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    if params.key?("headid")
      $pmid = params["headid"].to_i
    else
      $pmid = DepartmentHead.where.not(head_id: nil).select(:head_id).map(&:head_id).uniq.first
    end
    $alluser = User.where(status: 1).select(:id)
    dids = []
    did = DepartmentHead.where(head_id: $pmid).select(:department_id)
    @department_id = Department.where(id: did)
    @department_id.each do |dep|
      dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s)
      @ids.each do |obj|
        dids.push(obj.id)
      end
    end
    @kpi_raking = PeopleInformation.where(department_id: dids, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    if users_id.size == 0
      @ki_raking = nil
      @kpi_each = nil
    else
      sql = "select * from (select * from users   WHERE  users.id in (" + users_id.join(",") + "))a left join people_kis on a.id=people_kis.user_id AND `people_kis`.`version_id` = " + $kidanhgia.to_s + " order by a.id"
      @records_array = ActiveRecord::Base.connection.execute(sql)
      @ki_raking = @records_array.as_json
      @kpi_each = Project.find(1072).issues.where(:assigned_to_id => users_id).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order(:assigned_to_id)
    end
  end

  def save
    # PeopleInformation.where(employee_id: params[:user_code]).take.user_id
    uid = CustomValue.where(:custom_field_id => 55).where(:customized_type => 'Principal').where(:value => params[:user_code]).first.customized_id
    check_create = PeopleKi.where(user_id: uid, version_id: params[:version_id]).size
    if check_create > 0
      pkid = PeopleKi.where(user_id: uid, version_id: params[:version_id]).first.id
      old_ki = PeopleKi.where(user_id: uid, version_id: params[:version_id]).first.ki
      pki = PeopleKi.update(pkid, :location_compliance => params[:location], :kpi_type => params[:ki_type],
                            :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                            :manager_note => params[:manage_note], :note => params[:note], :flag => 0);
      unless old_ki == params[:ki]
        PeopleKiLog.create(:action => "update", :people_ki_id => pki.id, :head_id => User.current.id, :description => "Old_KI: " + old_ki + " - New_KI: " + pki.ki, :timestamp => DateTime.now)
        issue = Issue.where(:assigned_to_id => uid).where(:fixed_version_id => params[:version_id]).where(:tracker_id => 51).first
        if !issue.nil?
          note = Journal.new(
              :journalized_id => issue.id,
              :journalized_type => 'Issue',
              :user_id => User.current.id,
              :notes => "KI cũ: " + old_ki + " - KI mới: " + params[:ki]
          )
          note.save
        end
      end
    else

      pki = PeopleKi.create(:user_id => uid, :version_id => params[:version_id], :kpi_type => params[:ki_type], :location_compliance => params[:location],
                            :labor_rules_compliance => params[:labor_rules], :ki => params[:ki],
                            :manager_note => params[:manage_note], :note => params[:note]);
      PeopleKiLog.create(:action => "create", :people_ki_id => pki.id, :head_id => User.current.id, :description => pki.ki, :timestamp => DateTime.now)
      issue = Issue.where(:assigned_to_id => uid).where(:fixed_version_id => params[:version_id]).where(:tracker_id => 51).first
      if !issue.nil?
        note = Journal.new(
            :journalized_id => issue.id,
            :journalized_type => 'Issue',
            :user_id => User.current.id,
            :notes => "Xếp loại KI: " + pki.ki
        )
        note.save
      else
        issue = Issue.new(
            :tracker_id => 51,
            :project_id => 1072,
            :subject => "KI CBNV",
            :status_id => 37,
            :assigned_to_id => uid,
            :priority_id => 2,
            :fixed_version_id => params[:version_id],
            :author_id => 1,
        )
        if issue.save
          point = pki.kpi
          location = pki.location_compliance == 1 ? 152 : pki.location_compliance == 2 ? 153 : 154
          labor = pki.labor_rules_compliance == 1 ? 155 : pki.labor_rules_compliance == 2 ? 156 : 157
          note = pki.note.nil? ? '' : pki.note
          manager_note = pki.manager_note.nil? ? '' : pki.manager_note
          department_name = CustomValue.where(customized_id: uid, custom_field_id: 53).select(:value).take(1).nil? ? "" : CustomValue.where(customized_id: uid, custom_field_id: 53).select(:value).take(1).first.value
          if !CustomFieldEnumeration.find_by_name(pki.ki).nil?
            ki = CustomFieldEnumeration.find_by_name(pki.ki).id unless pki.ki.nil?
            pki.flag = 1
          else
            ki = nil
            pki.flag = 0
          end
          issue.custom_field_values = {223 => point, 224 => location, 225 => labor, 227 => ki, 240 => note, 241 => manager_note, 242 => department_name}
          issue.save
          note = Journal.new(
              :journalized_id => issue.id,
              :journalized_type => 'Issue',
              :user_id => User.current.id,
              :notes => "Xếp loại KI: " + CustomFieldEnumeration.find(ki).name
          )
          note.save
          pki.save
        end
      end

    end
  end

  def saveRendKI

    objects = params[:obj]
    objects.each do |key, value|
      uid = PeopleInformation.where(employee_id: value["user_code"]).take.user_id
      check_create = PeopleKi.where(user_id: uid, version_id: value["version_id"]).size
      if check_create > 0
        pkid = PeopleKi.where(user_id: uid, version_id: value["version_id"]).first.id
        old_ki = PeopleKi.where(user_id: uid, version_id: value["version_id"]).first.ki
        pki = PeopleKi.update(pkid, :location_compliance => value["location"], :kpi_type => value["ki_type"],
                              :labor_rules_compliance => value["labor_rules"], :ki => value["ki"],
                              :manager_note => value["manage_note"], :note => value["note"]);
        unless old_ki == value["ki"]
          PeopleKiLog.create(:action => "update", :people_ki_id => pki.id, :head_id => User.current.id, :description => "Old_KI: " + old_ki + " - New_KI: " + pki.ki, :timestamp => DateTime.now)
          issue = Issue.where(:assigned_to_id => uid).where(:fixed_version_id => value["version_id"]).where(:tracker_id => 51).first
          if !issue.nil?
            note = Journal.new(
                :journalized_id => issue.id,
                :journalized_type => 'Issue',
                :user_id => User.current.id,
                :notes => "KI cũ: " + old_ki + " - KI mới: " + value["ki"]
            )
            note.save
          end
        end
      else
        pki = PeopleKi.create(:user_id => uid, :version_id => value["version_id"], :kpi_type => value["ki_type"], :location_compliance => value["location"],
                              :labor_rules_compliance => value["labor_rules"], :ki => value["ki"],
                              :manager_note => value["manage_note"], :note => value["note"]);
        PeopleKiLog.create(:action => "create", :people_ki_id => pki.id, :head_id => User.current.id, :description => pki.ki, :timestamp => DateTime.now)
        issue = Issue.where(:assigned_to_id => uid).where(:fixed_version_id => value["version_id"]).where(:tracker_id => 51).first
        if !issue.nil?
          note = Journal.new(
              :journalized_id => issue.id,
              :journalized_type => 'Issue',
              :user_id => User.current.id,
              :notes => "Xếp loại KI: " + pki.ki
          )
          note.save
        else
          issue = Issue.new(
              :tracker_id => 51,
              :project_id => 1072,
              :subject => "KI CBNV",
              :status_id => 37,
              :assigned_to_id => uid,
              :priority_id => 2,
              :fixed_version_id => value["version_id"],
              :author_id => 1,
          )
          if issue.save
            point = pki.kpi
            location = pki.location_compliance == 1 ? 152 : pki.location_compliance == 2 ? 153 : 154
            labor = pki.labor_rules_compliance == 1 ? 155 : pki.labor_rules_compliance == 2 ? 156 : 157
            note = pki.note.nil? ? '' : pki.note
            manager_note = pki.manager_note.nil? ? '' : pki.manager_note
            department_name = CustomValue.where(customized_id: uid, custom_field_id: 53).select(:value).take(1).nil? ? "" : CustomValue.where(customized_id: uid, custom_field_id: 53).select(:value).take(1).first.value
            if !CustomFieldEnumeration.find_by_name(pki.ki).nil?
              ki = CustomFieldEnumeration.find_by_name(pki.ki).id unless pki.ki.nil?
              pki.flag = 1
            else
              ki = nil
              pki.flag = 0
            end
            issue.custom_field_values = {223 => point, 224 => location, 225 => labor, 227 => ki, 240 => note, 241 => manager_note, 242 => department_name}
            issue.save
            note = Journal.new(
                :journalized_id => issue.id,
                :journalized_type => 'Issue',
                :user_id => User.current.id,
                :notes => "Xếp loại KI: " + CustomFieldEnumeration.find(ki).name
            )
            note.save
            pki.save
          end
        end
      end
    end
  end

  def tcldsave
    uid = Department.where(id: params[:pmid]).first.head_id
    users_id = getallusers(uid)
    PeopleKi.where(version_id: params[:version_id], user_id: users_id).update_all(:submit_ki => params[:status])
    PeopleKiLock.where(lead_id: params[:pmid], version_id: params[:version_id]).update_all(:lead_id => params[:pmid], :version_id => params[:version_id], :status => params[:status]);
    $dids = []
    @department_id = Department.where(head_id: uid)
    @department_id.each do |dep|
      $dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
      @ids.each do |obj|
        $dids.push(obj.id)
      end
    end
    $alluser = User.where(status: 1).where.not(login: uid).select(:id)
    @kpi_raking = PeopleInformation.where(department_id: $dids, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    @issues = Issue.where(assigned_to_id: users_id, fixed_version_id: params[:version_id]).where.not(status_id: 35).where.not(tracker_id: 51)
    users_id.each do |id|
      # @userSMS = VecoPhone.where(name: User.find(id).login)
      @userSMS = VecoPhone.where(name: 'thangnv74')
      ki = PeopleKi.where(version_id: params[:version_id], user_id: id).first
      content = 'Thông báo KI trong kì '+Version.find(params[:version_id].to_i).name+': '+ki.ki+'. Nếu thông tin chưa chính xác, đồng chí vui lòng liên hệ quản lý trực tiếp.'
      handle_sendSMS(@userSMS,content)
    end
    render json: @issues
  end

  DB_HOST = "10.60.19.18"
  DB_USER = "hrmuser"
  DB_PASSWORD = "123456a@"
  DB = "smssupport"

  def handle_sendSMS(phone_array, content)
    client = Mysql2::Client.new(:host => DB_HOST, :username => DB_USER,
                                :password => DB_PASSWORD, :database => DB)

    phone_array.each_with_index do |user, index|
      phone = '84'.dup << user.phone[1..-1].dup
      insert = client.query("INSERT INTO sms (phone, content, sent)
                         VALUES ('#{phone}', '#{content}','#{0}')")
      client.close
    end
  end

  def getallusers(uid)
    $dids = []
    department_id = Department.where(head_id: uid)
    department_id.each do |dep|
      $dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
      ids.each do |obj|
        $dids.push(obj.id)
      end
    end
    $alluser = User.where(status: 1).where.not(login: User.current.login).select(:id)
    kpi_raking = PeopleInformation.where(department_id: $dids, user_id: $alluser).order(:user_id)
    users_id = []
    kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    return users_id
  end

  def saveAllKI
    $dids = []
    @department_id = Department.where(head_id: User.current.id)
    @department_id.each do |dep|
      $dids.push(dep.id)
      lft = Department.find(dep.id).lft
      rgt = Department.find(dep.id).rgt
      @ids = Department.where("lft > " + lft.to_s + " and rgt < " + rgt.to_s).where.not(ki_confirm: 1)
      @ids.each do |obj|
        $dids.push(obj.id)
      end
    end
    $alluser = User.where(status: 1).where.not(login: User.current.login).select(:id)
    @kpi_raking = PeopleInformation.where(department_id: $dids, user_id: $alluser).order(:user_id)
    users_id = []
    @kpi_raking.each do |kpi|
      users_id.push(kpi.user_id)
    end
    @issues = Issue.where(assigned_to_id: users_id, fixed_version_id: params[:version_id]).where.not(status_id: 35).where.not(tracker_id: 51)
    check_create = PeopleKiLock.where(lead_id: User.current.id, version_id: params[:version_id]).size
    PeopleKi.where(version_id: params[:version_id], user_id: users_id).update_all(:submit_ki => 1)
    PeopleKi.where(version_id: params[:version_id], user_id: users_id).each do |pki|
      PeopleKiLog.create(:action => params[:act], :people_ki_id => pki.id, :head_id => User.current.id, :description => pki.ki, :timestamp => DateTime.now)
    end
    if check_create > 0
      PeopleKiLock.where(lead_id: User.current.id, version_id: params[:version_id]).update_all(:lead_id => User.current.id, :version_id => params[:version_id], :status => params[:status]);
    else
      PeopleKiLock.create(:lead_id => User.current.id, :version_id => params[:version_id], :status => params[:status]);
    end
    render json: @issues
  end

  def get_user_kpi
    if params.key?("vid")
      $kidanhgia = params[:vid]
    else
      $kidanhgia = Project.find(1072).default_version_id
    end
    flash.delete(:notice)
    @kpi_open_dinh_luong = Project.find(1072).issues.where(:assigned_to => params[:uid]).where.not(:tracker_id => 51).where(:fixed_version_id => $kidanhgia).order("FIELD(status_id,36,34,33,32,29,35)")
    result = total_ti_trong(@kpi_open_dinh_luong, nil)
    @total_ti_trong = result[0]
    @total_cbnv_point = result[1]
    @total_qltt_point = result[2]
  end

  def total_ti_trong(kpis, cbnv_ki)
    titrong_total = 0
    cbnv_point_total = 0
    qltt_point_total = 0
    kpis.each do |kpi|
      if (kpi.status_id != 35)
        tytrong = issue_customfield_value(kpi, 139).to_i
        titrong_total += tytrong
        cbnv_point = issue_customfield_value(kpi, 140)
        if cbnv_point != ""
          cbnv_point_total += cbnv_point[0, 1].to_i * (tytrong / 100.0)
        end
        qltt_point = issue_customfield_value(kpi, 141)
        if qltt_point != ""
          qltt_point_total += qltt_point[0, 1].to_i * (tytrong / 100.0)
        end
      end
    end
    qltt_point_total = qltt_point_total.round(2)
    cbnv_point_total = cbnv_point_total.round(2)
    if !cbnv_ki.nil?
      cbnv_ki.kpi = qltt_point_total
      cbnv_ki.save
    end
    return [titrong_total, cbnv_point_total, qltt_point_total]
  end
end
