require 'test_helper'

class MailTemplatesControllerTest < ActionController::TestCase
  setup do
    @mail_template = mail_templates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:mail_templates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create mail_template" do
    assert_difference('MailTemplate.count') do
      post :create, mail_template: { content: @mail_template.content, mail_bcc: @mail_template.mail_bcc, mail_cc: @mail_template.mail_cc, mail_from: @mail_template.mail_from, mail_from_name: @mail_template.mail_from_name, mail_template_category: @mail_template.mail_template_category, mail_template_name: @mail_template.mail_template_name, subject: @mail_template.subject }
    end

    assert_redirected_to mail_template_path(assigns(:mail_template))
  end

  test "should show mail_template" do
    get :show, id: @mail_template
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @mail_template
    assert_response :success
  end

  test "should update mail_template" do
    put :update, id: @mail_template, mail_template: { content: @mail_template.content, mail_bcc: @mail_template.mail_bcc, mail_cc: @mail_template.mail_cc, mail_from: @mail_template.mail_from, mail_from_name: @mail_template.mail_from_name, mail_template_category: @mail_template.mail_template_category, mail_template_name: @mail_template.mail_template_name, subject: @mail_template.subject }
    assert_redirected_to mail_template_path(assigns(:mail_template))
  end

  test "should destroy mail_template" do
    assert_difference('MailTemplate.count', -1) do
      delete :destroy, id: @mail_template
    end

    assert_redirected_to mail_templates_path
  end
end
