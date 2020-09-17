# This file is a part of Redmine People (redmine_people) plugin,
# humanr resources management plugin for Redmine
#
# Copyright (C) 2011-2020 RedmineUP
# http://www.redmineup.com/
#
# redmine_people is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_people is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_people.  If not, see <http://www.gnu.org/licenses/>.

class PeopleQuery < Query
  self.queried_class = Principal

  VISIBILITY_PRIVATE = 0
  VISIBILITY_ROLES   = 1
  VISIBILITY_PUBLIC  = 2

  self.available_columns = [
    QueryColumn.new(:id, :sortable => "#{Person.table_name}.id", :default_order => 'desc', :caption => '#', :frozen => true, :inline => false),
    QueryColumn.new(:name, :sortable => lambda {Person.fields_for_order_statement}, :caption => :field_person_full_name),
    QueryColumn.new(:firstname, :sortable => "#{Person.table_name}.firstname", :caption => :field_firstname),
    QueryColumn.new(:lastname, :sortable => "#{Person.table_name}.lastname", :caption => :field_lastname),
    QueryColumn.new(:middlename, :sortable => "#{PeopleInformation.table_name}.middlename", :caption => :label_people_middlename),
    QueryColumn.new(:gender, :sortable => "#{PeopleInformation.table_name}.gender", :groupable => "#{PeopleInformation.table_name}.gender", :caption => :label_people_gender),
    QueryColumn.new(:email, :sortable => Redmine::VERSION.to_s >= '3.0' ? "email_addresses.address" : "#{Person.table_name}.mail", :caption => :field_mail),
    QueryColumn.new(:address, :sortable => "#{PeopleInformation.table_name}.address", :caption => :label_people_address),
    QueryColumn.new(:phone, :sortable => "#{PeopleInformation.table_name}.phone", :caption => :label_people_phone),
    QueryColumn.new(:skype, :sortable => "#{PeopleInformation.table_name}.skype", :caption => :label_people_skype ),
    QueryColumn.new(:twitter, :sortable => "#{PeopleInformation.table_name}.twitter", :caption => :label_people_twitter),
    QueryColumn.new(:facebook, :sortable => "#{PeopleInformation.table_name}.facebook", :caption => :label_people_facebook),
    QueryColumn.new(:linkedin, :sortable => "#{PeopleInformation.table_name}.linkedin", :caption => :label_people_linkedin),
    QueryColumn.new(:birthday, :sortable => "#{PeopleInformation.table_name}.birthday", :caption => :label_people_birthday),
    QueryColumn.new(:job_title, :sortable => "#{PeopleInformation.table_name}.job_title", :groupable => "#{PeopleInformation.table_name}.job_title", :caption => :label_people_job_title),
    QueryColumn.new(:background, :sortable => "#{PeopleInformation.table_name}.background", :caption => :label_people_background),
    QueryColumn.new(:appearance_date, :sortable => "#{PeopleInformation.table_name}.appearance_date", :caption => :label_people_appearance_date),
    QueryColumn.new(:last_login_on, :sortable => "#{Person.table_name}.last_login_on", :caption => :field_last_login_on),
    QueryColumn.new(:department_id, :sortable => "#{Department.table_name}.name", :groupable => "#{PeopleInformation.table_name}.department_id", :caption => :label_people_department),
    QueryColumn.new(:manager_id, :sortable => "#{Person.table_name}.firstname", :caption => :label_people_manager , :groupable => "#{PeopleInformation.table_name}.manager_id"),
    QueryColumn.new(:is_system, :sortable => "#{PeopleInformation.table_name}.is_system", :caption => :label_people_is_system),
    QueryColumn.new(:status, :sortable => "#{Person.table_name}.status", :caption => :field_status),
    QueryColumn.new(:tags, :caption => :label_people_tags_plural),
    QueryColumn.new(:created_on, :sortable => "#{Person.table_name}.created_on"),
    QueryColumn.new(:updated_on, :sortable => "#{Person.table_name}.updated_on"),
    QueryColumn.new(
      :workday_length,
      sortable: lambda {
        column = "#{PeopleInformation.table_name}.workday_length"
        "CASE WHEN #{column} IS NULL THEN #{Setting.plugin_redmine_people['workday_length']} ELSE #{column} END"
      },
      caption: :label_people_workday_length
    )
  ]

  scope :visible, lambda { |*args|
    user = args.shift || User.current

    if Redmine::VERSION.to_s < '2.4'
      field = 'is_public'
      public_value = true
      private_value = false
    else
      field = 'visibility'
      public_value = VISIBILITY_PUBLIC
      private_value = VISIBILITY_PRIVATE
    end

    if user.admin?
      where("#{table_name}.#{field} <> ? OR #{table_name}.user_id = ?", private_value, user.id)
    elsif user.logged?
      where("#{table_name}.#{field} = ? OR #{table_name}.user_id = ?", public_value, user.id)
    else
      where("#{table_name}.#{field} = ?", public_value)
    end
  }

  def visible?(user = User.current)
    return true if user.admin?
    case visibility
    when VISIBILITY_PUBLIC
      true
    else
      user.respond_to?(:id) && user.id == user_id
    end
  end

  def is_private?
    visibility == VISIBILITY_PRIVATE
  end

  def is_public?
    !is_private?
  end

  def visibility=(value)
    if Redmine::VERSION.to_s < '2.4'
      self.is_public = value.to_i == VISIBILITY_PUBLIC
    else
      self[:visibility] = value
    end
  end

  def visibility
    if Redmine::VERSION.to_s < '2.4'
      is_public ? VISIBILITY_PUBLIC : VISIBILITY_PRIVATE
    else
      self[:visibility]
    end
  end

  def editable_by?(user)
    return false unless user
    # Admin can edit them all and regular users can edit their private queries
    return true if user.admin? || (user_id == user.id)
    # Members can not edit public queries that are for all project (only admin is allowed to)
    is_public? && user.allowed_people_to?(:manage_public_people_queries)
  end

  def initialize(attributes = nil, *_args)
    super attributes
    self.filters ||= { 'status' => { :operator => '=', :values => ['1'] } }
  end

  def initialize_available_filters
    add_available_filter 'firstname', :type => :string, :order => 0
    add_available_filter 'lastname', :type => :string, :order => 1
    add_available_filter 'middlename', :type => :string, :order => 2, :name => l(:label_people_middlename)
    add_available_filter('gender', :type => :list_optional, :values => [[l(:label_people_male), 0], [l(:label_people_female), 1]],
                                   :name => l(:label_people_gender),
                                   :order => 3
    )

    add_available_filter 'mail', :type => :string, :order => 4, :name => l(:field_mail)
    add_available_filter 'address', :type => :string, :order => 5, :name => l(:label_people_address)
    add_available_filter 'phone', :type => :string, :order => 6, :name => l(:label_people_phone)
    add_available_filter 'skype', :type => :string, :order => 7, :name => l(:label_people_skype)
    add_available_filter 'twitter', :type => :string, :order => 8, :name => l(:label_people_twitter)
    add_available_filter 'facebook', :type => :string, :order => 9, :name => l(:label_people_facebook)
    add_available_filter 'linkedin', :type => :string, :order => 10, :name => l(:label_people_linkedin)
    add_available_filter 'birthday', :type => :date_past, :order => 11, :name => l(:label_people_birthday)
    add_available_filter 'job_title', :type => :string, :order => 12, :name => l(:label_people_job_title)
    add_available_filter 'background', :type => :string, :order => 13, :name => l(:label_people_background)
    add_available_filter 'appearance_date', :type => :date_past, :order => 14, :name => l(:label_people_appearance_date)
    add_available_filter 'last_login_on', :type => :date_past, :order => 15

    add_available_filter 'manager_id', type: :people, values: Person.managers.map { |p| [p.name.html_safe, p.id.to_s] }, order: 15, name: l(:label_people_manager)

    add_available_filter 'is_system', :type => :list, :values => [[l(:general_text_yes), ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')],
                                                                  [l(:general_text_no), ActiveRecord::Base.connection.quoted_false.gsub(/'/, '')]],
                                      :order => 16, :name => l(:label_people_is_system)

    statuses = [[l(:status_active), Principal::STATUS_ACTIVE.to_s],
                [l(:status_registered), Principal::STATUS_REGISTERED.to_s],
                [l(:status_locked), Principal::STATUS_LOCKED.to_s]]

    add_available_filter 'status', :type => :list_optional, :order => 17, :name => l(:field_status), :values => statuses
    add_available_filter 'created_on', :type => :date_past, :order => 18
    add_available_filter 'updated_on', :type => :date_past, :order => 19

    add_available_filter 'workday_length', type: :float, name: l(:label_people_workday_length)
    departments = []
    Department.department_tree(Department.order(:lft)) do |department, level|
      name_prefix = (level > 0 ? '-' * 2 * level + ' ' : '') #'&nbsp;'
      departments << [(name_prefix + department.name).html_safe, department.id.to_s]
    end
    add_available_filter('department_id', :type => :list_optional, :name => l(:label_people_department), :order => 18, :values => departments) if departments.any?
    add_available_filter('tags', :type => :list, :values => Person.available_tags.collect { |t| [t.name, t.name] }, :order => 19, :name => l(:label_people_tags_plural))

    custom_fields_filters = UserCustomField.where(:is_filter => true)
    if Redmine::VERSION.to_s < '2.4'
      custom_fields_filters = custom_fields_filters.where(:visible => true) unless User.current.admin?
    end
    add_custom_fields_filters(custom_fields_filters)
    add_available_filter 'previous_company_name', :type => :string, :order => 20, :name => l(:label_people_previous_company_name)
    add_available_filter 'previous_job_title', :type => :string, :order => 20, :name => l(:label_people_previous_job_title)

      end

  def default_columns_names
    @default_columns_names ||= [:id, :name, :email, :phone]
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup

    @available_columns += CustomField.where(:type => 'UserCustomField').all.find_all { |cf| User.current.admin? || cf.visible? }.collect { |cf| QueryCustomFieldColumn.new(cf) }
    @available_columns
  end

  def objects_scope(options = {})
    scope = Person.respond_to?(:visible) ? Person.visible : Person.logged

    options[:search].split(' ').each { |search_string| scope = scope.seach_by_name(search_string) } if options[:search]

    associations = options[:include] || []
    associations << :information
    unless options[:count_request]
      preloads  = [:department]
      preloads << :email_address if Redmine::VERSION.to_s >= '3.0'
    end

    unless filters['is_system']
      scope = scope.where("#{PeopleInformation.table_name}.is_system IS NULL OR #{PeopleInformation.table_name}.is_system = ?", false)
    end

    scope
      .eager_load(associations.uniq)
      .preload(preloads)
      .where(type: 'User')
      .where(statement)
      .where(options[:conditions])
  end

  def object_count
    objects_scope(count_request: true).count
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def object_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = objects_scope.
            joins(joins_for_order_statement(group_by_statement)).
            group(group_by_statement).count
      rescue ActiveRecord::RecordNotFound
        r = { nil => object_count }
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) { |h, k| h[c.custom_field.cast_value(k)] = r[k]; h }
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def results_scope(options = {})
    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    objects_scope(options)
      .preload(options[:preload])
      .joins(joins_for_order_statement(order_option.join(',')))
      .order(order_option)
      .limit(options[:limit])
      .offset(options[:offset])
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end
  [
    :phone, :address, :skype, :birthday, :job_title, :company, :middlename, :gender, :twitter,
    :facebook, :linkedin, :background, :appearance_date, :workday_length
  ].each do |f|
    define_method("sql_for_#{f}_field") do |field, operator, value|
      sql_for_field(field, operator, value, PeopleInformation.table_name, f)
    end
  end

  def sql_for_mail_field(field, operator, value)
    if Redmine::VERSION.to_s >= '3.0'
      value = value.join(',').to_s
      case operator
      when '='
        o1 = 'IN'
        o2 = '='
      when '~'
        o1 = 'IN'
        o2 = 'LIKE'
        value = "%#{value}%"
      when '!'
        o1 = 'NOT IN'
        o2 = '='
      when '!~'
        o1 = 'NOT IN'
        o2 = 'LIKE'
        value = "%#{value}%"
      when '!*'
        o1 = 'NOT IN'
        o2 = 'IS'
        value = 'NULL'
      else
        o1 = 'IN'
        o2 = 'IS NOT'
        value = 'NULL'
      end
      "#{Person.table_name}.id #{o1} (SELECT DISTINCT(#{EmailAddress.table_name}.user_id)
        FROM #{EmailAddress.table_name}
        WHERE #{EmailAddress.table_name}.address #{o2} '#{value}')"
    else
      sql_for_field(field, operator, value, User.table_name, 'mail')
    end
  end

  def sql_for_tags_field(_field, _operator, value)
    compare   = operator_for('tags').eql?('=') ? 'IN' : 'NOT IN'
    ids_list  = Person.tagged_with(value).collect{|person| person.id }.push(0).join(',')
    "( #{Person.table_name}.id #{compare} (#{ids_list}) ) "
  end

  def sql_for_is_system_field(field, operator, value)
    if value.try(:first) == ActiveRecord::Base.connection.quoted_true.gsub(/'/, '')
      val = Rails.version < '5.2' ? value : value.map { |v| v == QUOTED_TRUE ? true : false }
      sql_for_field(field, operator, val, PeopleInformation.table_name, 'is_system')
    end
  end

  def sql_for_manager_id_field(field, operator, value)
    if operator == '='
      sql_for_field(field, operator, value, PeopleInformation.table_name, 'manager_id')
    elsif operator == '!'
      "#{Person.table_name}.id NOT IN (SELECT DISTINCT(#{PeopleInformation.table_name}.user_id)
        FROM #{PeopleInformation.table_name}
        WHERE #{PeopleInformation.table_name}.manager_id = #{value.try(:first).to_i})"
    end
  end

  def sql_for_previous_company_name_field(field, operator, value)
    sql_for_work_experience_field(field, operator, value, 'previous_company_name')
  end

  def sql_for_previous_job_title_field(field, operator, value)
    sql_for_work_experience_field(field, operator, value, 'job_title')
  end

  def sql_for_department_id_field(field, operator, value)
    department_ids = value
    department_ids += Department.where(:id => value).map(&:descendants).flatten.collect { |c| c.id.to_s }.uniq
    sql_for_field(field, operator, department_ids, PeopleInformation.table_name, 'department_id')
  end

  def contact_query_values(values)
    scope = Person.where(:id => values)
    scope = scope.visible if Person.respond_to?(:visible)
    scope.map { |c| [c.name.html_safe, c.id.to_s] }
  end
  private

  def sql_for_work_experience_field(field, operator, value, table_field)
    compare = (operator == '!' || operator == '!~') ? 'NOT IN' : 'IN'
    work_expiriences = PeopleWorkExperience.where(sql_for_field(field, operator, value, PeopleWorkExperience.table_name, table_field))
    ids_list = work_expiriences.map(&:user_id).flatten.collect{|c| c.to_s}.uniq.reject(&:blank?).join(',')
    ids_list = 'NULL' if ids_list.blank?
    "( #{Person.table_name}.id #{compare} (#{ids_list}) ) "
  end
end
