require File.expand_path('../../test_helper', __FILE__)

class IssueTest < ActiveSupport::TestCase
  fixtures :projects,
           :users, :email_addresses, :user_preferences,
           :roles, :members, :member_roles,
           :issues, :issue_statuses, :issue_relations,
           :versions, :trackers, :projects_trackers,
           :issue_categories, :enabled_modules,
           :enumerations, :attachments, :workflows,
           :custom_fields, :custom_values,
           :custom_fields_projects, :custom_fields_trackers,
           :time_entries, :journals, :journal_details,
           :queries, :repositories, :changesets

  include Redmine::I18n

  def setup
    set_language_if_valid 'en'
    @default_custom_field = create_default_serial_number_field
  end

  def teardown
    User.current = nil
  end

  def test_create_with_changed_serial_number_halfway
    issue = Issue.new(:project_id => 1, :tracker_id => 1, :author_id => 3, :subject => 'test_create_1')
    assert issue.save
    assert_added_serial_number(issue.id, 'MCC-0001', @default_custom_field)

    # changed regexp(forced)
    @default_custom_field.update_attributes(regexp: 'ABC-{0001}')

    issue = Issue.new(:project_id => 1, :tracker_id => 3, :author_id => 3, :subject => 'test_create_2')
    assert issue.save
    assert_added_serial_number(issue.id, 'MCC-0002', @default_custom_field)
  end

end
