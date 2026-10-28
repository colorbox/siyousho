require "application_system_test_case"

class PagesTest < ApplicationSystemTestCase
  test "visiting the index and about pages" do
    visit root_path
    assert_text "Hello from Rails"
    click_link "About"
    assert_text "About This Application"
    click_link "Home"
    assert_selector "h1", text: "Welcome"
  end

  test "signing up" do
    visit root_path
    click_link "Sign Up"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password123"
    fill_in "Password confirmation", with: "password123"
    click_button "Create Account"
    assert_text "Welcome! You have signed up successfully."
    assert_current_path user_dashboard_path
  end

  test "日本語のテスト名でも仕様書を生成する" do
    visit root_path
    within("h1") do
      assert_text "Welcome"
    end
    click_link "About"
    assert_text "About This Application"
  end
end
