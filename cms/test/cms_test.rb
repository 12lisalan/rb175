ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def test_index
    files = ["about.txt", "changes.txt"]
    files.each{|file| create_document file}

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]

    files.each{|file| assert_includes last_response.body, file}
  end

  def test_txt
    create_document "history.txt", "some stuff about history"
    get "/history.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]

    assert_includes last_response.body, "some stuff about history"
  end

  def test_no_file
    get "/some_file"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "some_file does not exist."

    get "/"
    refute_includes last_response.body, "some_file does not exist."
  end

  def test_markdown
    create_document "about.md", "# Ruby is..."
    get "/about.md"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_edit
    create_document "about.txt", "some stuff about about.txt"

    get "/about.txt/edit"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "some stuff about about.txt"

    modified_body = "some stuff about about.txt + new content"
    post "/about.txt", content: modified_body
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "about.txt has been updated."

    # checking if about.txt is updated
    get "/about.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, modified_body
  end

  def test_view_new_file_form
    get "/new"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Add a new document"
  end

  def test_create_file_without_name
    post "/new", file_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required."
  end

  def test_new_file
    post "/new", file_name: "test.txt"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "test.txt was created."
  end

  def test_delete_file
    create_document "delete.txt"
    post "/delete.txt/delete"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "delete.txt has been deleted."

    get "/"
    refute_includes last_response.body, "delete.txt"
  end

  def test_load_signin_page
    get "/"
    assert_includes last_response.body, "Sign In"

    get "/users/signin"
    assert_includes last_response.body, "<input"
  end

  def test_signin_error
    get "/signin", username: "username", password: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_signin_success
    get "/signin", username: "admin", password: "password"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Welcome!"
    assert_includes last_response.body, "Sign Out"
  end

  def test_signout
    get "/signin", username: "admin", password: "password"
    get last_response["Location"]

    get "/signout"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "You have been signed out."
    assert_includes last_response.body, "Sign In"
  end
end


