
require 'test/unit'
require 'solaris/util'

# Unit tests for utility module.
class TestUtil < Test::Unit::TestCase #:nodoc:

  def test_to_dir_to_file_mutually_exclusive
    assert_raise( ArgumentError ) do
      Solaris::Util.download!('http://example.com',
                              :to_dir => 'dir',
                              :to_file => 'file')
    end
  end

  def test_user_without_password
    assert_raise( ArgumentError ) do
      Solaris::Util.download!('http://example.com',
                              :user => 'user')
    end
  end

  def test_password_without_user
    assert_raise( ArgumentError ) do
      Solaris::Util.download!('http://example.com',
                              :password => 'password')
    end
  end

end

