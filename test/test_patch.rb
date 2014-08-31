require 'test/unit'
require 'solaris/patch'

# Unit tests for class Patch.
class TestPatch < Test::Unit::TestCase #:nodoc:

  def test_new_string_major_only
    patch = Solaris::Patch.new('123456')
    assert_equal(123456, patch.major)
    assert_nil(patch.minor)
  end

  def test_new_int_major_only
    patch = Solaris::Patch.new(123456)
    assert_equal(123456, patch.major)
    assert_nil(patch.minor)
  end

  def test_new_string_minor_only
    assert_raise(ArgumentError) do
      Solaris::Patch.new('-78')
    end
  end

  def test_new_string_major_and_minor
    patch = Solaris::Patch.new('123456-78')
    assert_equal(123456, patch.major)
    assert_equal(78, patch.minor)
  end

  def test_new_int_major_and_minor
    patch = Solaris::Patch.new(123456, 78)
    assert_equal(123456, patch.major)
    assert_equal(78, patch.minor)
  end

  def test_new_no_args
    patch = Solaris::Patch.new()
    assert_nil(patch.major)
    assert_nil(patch.minor)
  end

  def test_new_valid_opts
    patch = Solaris::Patch.new('123456-78')
    assert_equal(123456, patch.major)
    assert_equal(78, patch.minor)
  end

  def test_to_s
    patch = Solaris::Patch.new('123456-78')
    assert_equal('123456-78', patch.to_s)
  end

  def test_to_s_padding
    patch = Solaris::Patch.new('123456-7')
    assert_equal('123456-07', patch.to_s)
  end

  def test_to_s_major_only
    patch = Solaris::Patch.new(123456)
    assert_equal('123456', patch.to_s)
  end

  def test_comparison
    assert(Solaris::Patch.new('123456-78') == Solaris::Patch.new('123456-78'))
    assert(Solaris::Patch.new('123456-1') == Solaris::Patch.new('123456-01'))
    assert(Solaris::Patch.new('123456') == Solaris::Patch.new('123456'))
    assert(Solaris::Patch.new('123456-78') < Solaris::Patch.new('123456-79'))
    assert(Solaris::Patch.new('123456-78') < Solaris::Patch.new('123457-78'))
    assert(Solaris::Patch.new('123456-1') < Solaris::Patch.new('123456-10'))
  end

  def test_download_requires_major
    patch = Solaris::Patch.new
    patch.minor = 1
    assert_raise(ArgumentError) { patch.download_patch! }
    assert_raise(ArgumentError) { patch.download_readme! }
  end

  def test_download_requires_minor
    patch = Solaris::Patch.new
    patch.major = 123456
    assert_raise(ArgumentError) { patch.download_patch! }
    assert_raise(ArgumentError) { patch.download_readme! }
  end

  def test_download!
    skip 'Mock required'
  end

  def test_pad_minor
    assert_equal('00', Solaris::Patch.pad_minor(0))
    assert_equal('01', Solaris::Patch.pad_minor(1))
    assert_equal('12', Solaris::Patch.pad_minor(12))
    assert_equal('123', Solaris::Patch.pad_minor(123))
  end

end
